require 'rack'
require 'rack/request'
require 'rack/respond_to'
require 'link_header'

module DescribedRoutes
  module Middleware
    #
    # Abstract Rack middleware for described_routes.  It serves ResourceTemplate data at the configured descrbed_routes path and
    # adds link headers to regular requests whose routing matches a ResourceTemplate.
    #
    # It must be customised to the web framework in use - override #get_resource_templates and #get_resource_routing.
    #
    class Base
      include Rack::RespondTo
      
      # The default options parameter to #link_headers; controls which links appear in html link elements 
      DEFAULT_OPTIONS = {
        :describedby           => true,
        :self                  => false,
        :up                    => false,
        :related               => false,
        :registered_rels       => {'edit' => 'edit', 'up' => 'up'},
        :described_routes_path => '/described_routes'
      }
      
      def initialize(app, options={})
        @app = app

        @options = DEFAULT_OPTIONS.merge(options)
        DEFAULT_OPTIONS.keys.each do |option|
          instance_variable_set("@option_#{option}", @options[option])
        end
        
        @inited = false
      end
      
      #
      # From the first request, initialize @root, @described_routes_uri and @resource_templates
      #
      def init_from_first_req(req)
        raise "no request host" unless req.host
        
        @root = "http://#{req.host}"
        @root += ":#{req.port}" if req.port && req.port != 80
        @root += "#{script_name}" if req.script_name && !req.script_name.empty?
      
        @described_routes_uri = @root + @option_described_routes_path

        @resource_templates = get_resource_templates(@root)
        raise "get_resource_templates(#{@root.inspect}) failed; no resource templates!" unless @resource_templates

        @inited = true
      end

      #
      # Does nothing - override in framework-specific middleware to return the top level ResourceTemplates object
      #
      def get_resource_templates
        nil
      end
      
      #
      # Does nothing - override in framwork-specific middleware to return the ResourceTemplate and params hash matching the
      # request, otherwise a pair of nils
      #
      def get_resource_routing(req)
        [nil, nil]
      end

      #
      # Process a Rack request, either returning ResourceTemplate data fif the request matches the described_routes path,
      # otherwise passing on the request the application and adding a link header to the response.
      #
      def call(env)
        # puts "\n", "-" * 80, "\n", env.map{|k, v| "#{k} => #{v.inspect}"}

        req = Rack::Request.new(env)
        
        init_from_first_req(req) unless @inited

        if req.path =~ %r(^#{@option_described_routes_path}(/([^/.]+)?)?(\.([a-z]+))?)
          serve_resource_template_data(req, $2, $3)
        else
          call_with_link_header(req)
        end
      end
      
      #
      # Handles requests for ResourceTemplate data
      #
      def serve_resource_template_data(req, route_name, format)
        if route_name   # /described_routes/{route_name}
          resource_template = @resource_templates.all_by_name[route_name]
          unless resource_template
            return [404, {'Content-Type' => 'text/plain'}, ["No ResourceTemplate named #{route_name.inspect}"]]
          end
          target = resource_template
          rel = "index" # link header will point to the site ResourceTemplates description
        else
          rel = "self"  # this is the site ResourceTemplates description
          target = @resource_templates
        end        
        expanded = target.partial_expand(req.GET)
        Rack::RespondTo.env = req.env
        if format
          # Format extension overrides any accept header
          Rack::RespondTo.media_types = [Rack::Mime::MIME_TYPES[format]]
        else
          # Supported formats, .text preferred.  No html yet!
          Rack::RespondTo.media_types = %w(.text .json .yaml .xml).map{|format| Rack::Mime::MIME_TYPES[format]}
        end

        body = respond_to do |format|
          format.text {expanded.to_text}
          format.json {expanded.to_json}
          format.yaml {expanded.to_yaml}
          format.xml  {expanded.to_xml(Builder::XmlMarkup.new(:indent => 2)).target!}
        end

        headers = {
          'Link' => %Q(<#{@described_routes_uri}>; rel="#{rel}"; meta="ResourceTemplates"),
          'Content-Type' => Rack::RespondTo.selected_media_type
        }
        
        [200, headers, [body]]
      end
      
      #
      # Passes on a request to the application and adds a link header to the response
      #
      def call_with_link_header(req)
        status, headers, body = @app.call(req.env)
        
        resource_template, params = get_resource_routing(req)
        if resource_template
          headers = headers.merge("Link" => make_link_header(resource_template, params, @root + req.fullpath).to_s)
        end
        
        [status, headers, body]
      end
            
      # Returns a LinkHeader object that represents the required links.
      #
      # Link relation types ("rel" attributes) will contain a standard type ('self', 'up', 'describedby') &/or an extension type
      # in the form "described_route_url(name)#rel", using the name and rel of the resource template.
      #
      # The output is filtered by the options hash, with members :self, :describedby, :up, :related.
      #
      # TODO move this to ResourceTemplate
      #
      def make_link_header(resource_template, params, request_uri)
        links = []

        type_prefix = @described_routes_uri + '#'
        #
        # For the application's root, the link with rel="describedby" has meta="ResourceTemplates" and it refers to a list of all
        # top level resource templates. Otherwise, rel="describedby" has meta="ResourceTemplate" and it refers to a single resource
        # template (together with any descendants).
        #
        if resource_template.name == 'root'
          described_by = @described_routes_uri
          related = @resource_templates
          meta = "ResourceTemplates"
        else
          described_by = @described_routes_uri + "/" + resource_template.name
          related = resource_template.resource_templates
          meta = "ResourceTemplate"
        end

        #
        # Add any query parameters to the rel="describedby" link
        #
        if params.empty?
          described_by_with_params = described_by
        else
          described_by_with_params = described_by + '?' + params.to_query
        end

        # data for rel="self"
        links << LinkHeader::Link.new(request_uri, [['rel', 'self'], ['role', type_prefix + resource_template.name]]) if @option_self

        # data for rel="described_by"
        links << LinkHeader::Link.new(described_by_with_params, [['rel', 'describedby'], ['meta', meta]]) if @option_describedby

        # data for rel="up"
        # TODO move this to ResourceTemplate
        if @option_up
          if resource_template.parent
            links << LinkHeader::Link.new(
                        resource_template.parent.uri_for(params),
                        [['rel', 'up'], ['role', type_prefix + resource_template.parent.name]])
          elsif resource_template.name != 'root'
            links << LinkHeader::Link.new(@root + '/', [['rel', 'up'], ['role', type_prefix + 'root']])
          end
        end

        # data for rel="related"
        if @option_related
          related.expand_links(params).each do |l|
            if l.name != resource_template.name
              rel = l.rel || l.name
              rels = [['rel', described_by + '#' + rel]]
              if l.rel
                registered_rel = @option_registered_rels[rel]
                if registered_rel
                  rels.unshift(['rel', registered_rel])
                end
              end
              links << LinkHeader::Link.new(l.uri, rels + [['role', type_prefix + l.name]])
            end
          end
        end
        LinkHeader.new(links)
      end
    end
  end
end
