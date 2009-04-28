require 'described_routes'

module DescribedRoutes
  module RailsRoutes
    #
    # Based on the implementation of "rake routes".  Returns a hash of Rails path specifications (slightly normalized)
    # mapped to hashes of the attributes we need. 
    #
    def self.get_rails_resources
      ActionController::Routing::Routes.routes.inject({}) do |resources, route|
        name = ActionController::Routing::Routes.named_routes.routes.index(route).to_s
        controller = route.parameter_shell[:controller]
        action = route.parameter_shell[:action]
        options = [route.conditions[:method]].flatten.map{|option| option.to_s.upcase}
        segs = route.segments.inject("") {|str,s| str << s.to_s }
        segs.chop! if segs.length > 1

        # prefix :id parameters consistently
        # TODO - probably a better way to do this, just need a pattern that matches :id and not :id[a-zA-Z0-9_]+
        segs.gsub!(/:[a-zA-Z0-9_]+/) do |match|
          if match == ":id" && controller
            ":#{controller.singularize.sub(/.*\//, "")}_id"
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
          #   name              #=>  "edit_user"

          # create a new route hash
          resource = {
            "path_template" => template,
            "options" => options,
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
    # Takes the routes from Rails and produces the required tree structure.
    #
    def self.get_resources(base_url = nil)
      resources = get_rails_resources
      resources.delete_if{|k, v| v["name"].blank? or v["name"] =~ /^formatted/}

      key_tree = make_key_tree(resources.keys.sort){|possible_prefix, key|
        key[0...possible_prefix.length] == possible_prefix && possible_prefix != "/"
      }

      tree = map_key_tree(key_tree) do |key, children|
        resource = resources[key]
        resource["resource_templates"] = children unless children.empty?
        resource.delete("options") if resource["options"] == [""]
        resource["uri_template"] = base_url + resource["path_template"] if base_url && resource["path_template"]

        # compare parent and child names, and populate "rel" with either
        # 1) a prefix (probably an action name)
        # 2) a suffix (probably a nested resource)
        # If neither applies, let's hope the child is identified by parameter (i.e. the parent is a collection)
        # TODO rewrite this so that it's done when the child is created
        name = resource["name"]
        prefix = /^(.*)_#{name}$/
        suffix = /^#{name}_(.*)$/
        children.each do |child|
          child_name = child["name"]
          if child_name =~ prefix
            child["rel"] = $1
          elsif child_name =~ suffix
            child["rel"] = $1
          end 
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
