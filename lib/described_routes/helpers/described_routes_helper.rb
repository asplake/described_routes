require 'link_header'

module DescribedRoutes
  module DescribedRoutesHelper
    # Map rels to standard relation types, used by #make_link_header
    REGISTERED_RELS = {
      'edit' => 'edit',
      'up'   => 'up'
    }
    
    # The default options parameter to #link_elements; controls which links appear in html link elements 
    LINK_ELEMENT_OPTIONS = {
      :self => false, :describedby => true, :up => false, :related => false
    }
    
    # The default options parameter to #link_headers; controls which links appear in html link elements 
    LINK_HEADER_OPTIONS = {
      :self => false, :describedby => true, :up => false, :related => false
    }
    
    # get the resource template structure, initialised (once) from Rails routes
    def resource_templates
      @@resource_templates ||= begin
        base_url = root_url rescue nil
        RailsRoutes.get_resource_templates(base_url)
      end
    end
    
    # get the resource template for the current request
    def resource_template
      r = resource_templates.routing[[controller_name, action_name]]
      r[0] if r
    end
    
    # combined path and query parameters (not POST parameters), with the id param renamed to foo_id (say)
    def resource_parameters
      @resource_parameters ||= begin
        p = request.path_parameters.merge(request.query_parameters)
        r = resource_templates.routing[[controller_name, action_name]]
        if r && r[1] && p[:id]
          p[r[1]] = p.delete(:id)
        end
        p.except("action", "controller")
      end
    end
  
    # Render links as <link <url> rel=<rel> ... type=<type>> elements.  Add to the <head> part of your layout with:
    #   <%= link_elements %>
    def link_elements(separator="\n", options=LINK_ELEMENT_OPTIONS)
      make_link_header(options).to_html(separator)
    end
  
    # Sets a link header in the response
    #     after_filter :set_link_header 
    def set_link_header(options=LINK_HEADER_OPTIONS)
      response.headers["Link"] = make_link_header(options).to_s
    end

    # Returns a LinkHeader object that represents the required links.
    #
    # Link relation types ("rel" attributes) will contain a standard type ('self', 'up', 'describedby') &/or an extension type
    # in the form "described_route_url(name)#rel", using the name and rel of the resource template.
    #
    # The output is filtered by the options hash, with members :self, :describedby, :up, :related.
    #
    def make_link_header(options)
      links = []
      rt = resource_template
      if rt
        type_prefix = described_routes_url + '#'
        #
        # For the application's root, the link with rel="describedby" has meta="ResourceTemplates" and it refers to a list of all
        # top level resource templates. Otherwise, rel="describedby" has meta="ResourceTemplate" and it refers to a single resource
        # template (together with any descendants).
        #
        if rt.name == 'root'
          described_by = described_routes_url
          related = resource_templates
          meta = "ResourceTemplates"
        else
          described_by = described_route_url(rt.name)
          related = rt.resource_templates
          meta = "ResourceTemplate"
        end
        
        #
        # Add any query parameters to the rel="describedby" link
        #
        if resource_parameters.empty?
          described_by_with_params = described_by
        else
          described_by_with_params = described_by + '?' + resource_parameters.to_query
        end
        
        # data for rel="self"
        links << LinkHeader::Link.new(request.url, [['rel', 'self'], ['role', type_prefix + rt.name]]) if options[:self]

        # data for rel="described_by"
        links << LinkHeader::Link.new(described_by_with_params, [['rel', 'describedby'], ['meta', meta]]) if options[:describedby]

        # data for rel="up"
        # TODO move this to ResourceTemplate
        if options[:up]
          if rt.parent
            links << LinkHeader::Link.new(rt.parent.uri_for(resource_parameters), [['rel', 'up'], ['role', type_prefix + rt.parent.name]])
          elsif rt.name != 'root'
            links << LinkHeader::Link.new(root_url, [['rel', 'up'], ['role', type_prefix + 'root']])
          end
        end

        # data for rel="related"
        if options[:related]
          related.expand_links(resource_parameters).each do |l|
            if l.name != rt.name
              rel = l.rel || l.name
              rels = [['rel', described_by + '#' + rel]]
              if l.rel
                registered_rel = REGISTERED_RELS[rel]
                if registered_rel
                  rels.unshift(['rel', registered_rel])
                end
              end
              links << LinkHeader::Link.new(l.uri, rels + [['role', type_prefix + l.name]])
            end
          end
        end
      end
      LinkHeader.new(links)
    end
  end
end
