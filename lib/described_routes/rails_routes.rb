require 'resource_template'
require 'active_support'

module DescribedRoutes
  module RailsRoutes
    # This is just glue really.  It captures some extra data in the top level ResourceTemplates container to help address a
    # couple of issues:
    # 1) Inconsistent id parameter naming - id become {foo}_id when foo becomes the parent of another type of resources
    # 2) Rails doesn't pass in the route object (not even its name) when routing a request to a controller so we have
    # to keep enough information here for us to be able to guess it. Controller and action will be enough 99% of the time.
    class RailsResourceTemplates < ResourceTemplate::ResourceTemplates
      # Maps [controller, action] to [resource_template, id_name]
      attr_reader :routing
      
      def initialize(parsed)
        super
        
        @routing = {}
        save_routing(parsed)
      end
      
      private
      
      def save_routing(parsed)
        if parsed
          parsed.each do |p|
            @routing[[p["controller"], p["action"]]] = [all_by_name[p["name"]], p["id_name"]]
            save_routing(p["resource_templates"])
          end
        end
      end
    end
    
    #
    # Hook to customise the "parsed" (Array/Hash) data.  For example, to remove certain sensitive routes:
    #
    #   DescribedRoutes::RailsRoutes.parsed_hook = lambda {|a| a.reject{|h| h["name"] =~ /^admin/}}
    #
    mattr_accessor :parsed_hook
    
    #
    # Process Rails routes and return an array of ResourceTemplate objects.
    #
    def self.get_resource_templates(base_url=nil, routing=nil)
      parsed = get_parsed_rails_resources(base_url)
      parsed = parsed_hook.call(parsed) if parsed_hook
      RailsResourceTemplates.new(parsed)
    end

    #
    # Based on the implementation of "rake routes".  Returns a hash of Rails path specifications (slightly normalized)
    # mapped to hashes of the attributes we need. 
    #
    def self.get_rails_resources #:nodoc:
      ActionController::Routing::Routes.routes.inject({}) do |resources, route|
        name = ActionController::Routing::Routes.named_routes.routes.index(route).to_s
        controller = route.parameter_shell[:controller]
        action = route.parameter_shell[:action]
        options = [route.conditions[:method]].flatten.map{|option| option.to_s.upcase}
        segs = route.segments.inject("") {|str,s| str << s.to_s }
        segs.chop! if segs.length > 1

        # prefix :id parameters consistently
        # TODO - probably a better way to do this, just need a pattern that matches :id and not :id[a-zA-Z0-9_]+
        id_name = nil
        segs.gsub!(/:[a-zA-Z0-9_]+/) do |match|
          if match == ":id" && controller
            id_name = (controller == "described_routes/rails") ? "route_name" : "#{controller.singularize.sub(/.*\//, "")}_id"
            ':' + id_name
          else
            match
          end
        end

        # ignore optional format parameter when comparing paths
        key = segs.sub("(.:format)", "")
        if resources[key]
          # we've seen the (normalised) path before; add to options
          resources[key]["options"] += options
        else
          template = segs

          # collect & format mandatory parameters
          params = []
          template.gsub!(/:[a-zA-Z0-9_]+/) do |match|
            param = match[1..-1]
            param = controller.singularize.sub(/.*\//, "") + "_id" if param == "id" && controller
            params << param
            "{#{param}}"
          end

          # collect & format optional format parameter
          optional_params = []
          template.sub!("(.{format})") do |match|
            optional_params << "format"
            "{-prefix|.|format}"
          end
          params -= optional_params

          # so now we have (for example):
          #   segs              #=> "/users/:user_id/edit(.:format)" (was "/users/:id")
          #   key               #=> "/users/:user_id/edit"
          #   template          #=> "/users/{user_id}/edit"
          #   params            #=> ["user_id"]
          #   optional_params   #=> ["format"]
          #   action            #=> "edit"
          #   options           #=> ["GET"]
          #   name              #=> "edit_user"
          #   controller        #=> "rails"
          #   id_name           #=> "user_id"

          # create a new route hash
          resource = {
            "path_template" => template,
            "options"       => options,
            "controller"    => controller,
            "action"        => action,
            "id_name"       => id_name
          }
          resource["params"] = params unless params.empty?
          resource["optional_params"] = optional_params unless optional_params.empty?

          resources[key] = resource
        end

        # this may be the first time we've seen a good name for this key
        resources[key]["name"] ||= name unless name.blank? or name =~ /^formatted/

        resources
      end
    end

    #
    # Takes the routes from Rails and produces the required tree structure.  Returns the "parsed" format - i.e. a representation
    # in Ruby Array and Hash objects
    #
    def self.get_parsed_rails_resources(base_url = nil) #:nodoc:
      base_url = base_url.sub(/\/$/, '') if base_url
      resources = get_rails_resources
      resources.delete_if{|k, v| v["name"].blank? or v["name"] =~ /^formatted/}

      key_tree = make_key_tree(resources.keys.sort){|possible_prefix, key|
        key[0...possible_prefix.length] == possible_prefix && possible_prefix != "/"
      }

      tree = map_key_tree(key_tree) do |key, children|
        resource = resources[key]
        
        resource.delete("options") if resource["options"] == [""]
        resource["uri_template"] = base_url + resource["path_template"] if base_url && resource["path_template"]

        # compare parent and child names, and populate "rel" with either
        # 1) a prefix (probably an action name)
        # 2) a suffix (probably a nested resource)
        # 3) the child's name if the parent and child's params are identical
        # If none of the above applies, the child must be identifable by parameter
        name = resource["name"]
        prefix = /^(.*)_#{name}$/
        suffix = /^#{name}_(.*)$/
        children.each do |child|
          child_name = child["name"]
          if child_name =~ prefix
            child["rel"] = $1
          elsif child_name =~ suffix
            child["rel"] = $1
          elsif child["params"] == resource["params"]
            child["rel"] = child["name"]
          end
        end
    
        controller = resource["controller"]
        unless children.empty?
          resource["resource_templates"] = children.sort_by{|c|
            [
              (c["controller"] == controller) ? "" : c["controller"],  # group by controller, parent controller first
              (c["params"] || []).length,                              # fewer params first
              c["name"]                                                # make determininistic 
            ]
          }
        end

        resource
      end
    end
    
    #
    # Depth-first tree traversal
    #
    #   tree = [["/", []], ["/a", [["/a/b", [["/a/b/c", []]]], ["/a/d", []]]], ["/b", []]]
    #   map_key_tree(tree){|key, processed_children| {key => processed_children}}
    #   # => [{"/"=>[]}, {"/a"=>[{"/a/b"=>[{"/a/b/c"=>[]}]}, {"/a/d"=>[]}]}, {"/b"=>[]}]
    #
    def self.map_key_tree(tree, &blk) #:nodoc:
      tree.map do |pair|
        key, children = pair
        blk.call(key, map_key_tree(children, &blk))
      end
    end
  
    #
    # Turns a sorted array of strings into a tree structure as follows:
    #
    #   make_key_tree(["/", "/a", "/a/b", "/a/b/c", "/a/d", "/b"]){|possible_prefix, route|
    #     route[0...possible_prefix.length] == possible_prefix && possible_prefix != "/"
    #   }
    #   => [["/", []], ["/a", [["/a/b", [["/a/b/c", []]]], ["/a/d", []]]], ["/b", []]]
    #
    # Note that in the example (as in is actual usage in this module), we choose not to to have the root resource ("/") as
    # the parent of all other resources.
    #
    def self.make_key_tree(sorted_keys, &is_prefix) #:nodoc:
      head, *tail = sorted_keys
      if head
        children, siblings = tail.partition{|p| is_prefix.call(head, p)}
        [[head, make_key_tree(children, &is_prefix)]] + make_key_tree(siblings, &is_prefix)
      else
        []
      end
    end
  end
end
