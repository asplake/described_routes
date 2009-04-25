
module DescribedRoutes
  VERSION = "0.0.1"
  #
  # Based on the implementation of "rake routes".  Returns a hash of Rails path specifications (slightly normalized)
  # mapped to hashes of the attributes we need. 
  #
  def self.get_rails_resources
    ::ActionController::Routing::Routes.routes.inject({}) do |resources, route|
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
puts template
        template.sub!("(.{format})") do |match|
          optional_params << "format"
          "{-prefix|.|format}"
        end
puts template
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

  #:nodoc:
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
  def self.make_key_tree(sorted_keys, &is_prefix)
    head, *tail = sorted_keys
    if head
      children, siblings = tail.partition{|p| is_prefix.call(head, p)}
      [[head, make_key_tree(children, &is_prefix)]] + make_key_tree(siblings, &is_prefix)
    else
      []
    end
  end

  #
  # Takes the routes from Rails and produces the required tree structure.  #to_yaml and #to_json can
  # be called on the result directly.  If XML is required, see #resource_xml.
  #
  def self.get_resource_tree
    resources = get_rails_resources
    resources.delete_if{|k, v| v["name"].blank? or v["name"] =~ /^formatted/}

    key_tree = make_key_tree(resources.keys.sort){|possible_prefix, key|
      key[0...possible_prefix.length] == possible_prefix && possible_prefix != "/"
    }

    tree = map_key_tree(key_tree) do |key, children|
      resource = resources[key]
      resource["resources"] = children unless children.empty?
      resource.delete("options") if resource["options"] == [""]

      # compare parent and child names, and populate "rel" with either
      # 1) a prefix (probably an action name)
      # 2) a suffix (probably a nested resource)
      # If neither applies, let's hope the child is identified by parameter (i.e. the parent is a collection)
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

  #:nodoc:
  #
  # Depth-first tree traversal
  #
  #   tree = [["/", []], ["/a", [["/a/b", [["/a/b/c", []]]], ["/a/d", []]]], ["/b", []]]
  #   map_key_tree(tree){|key, processed_children| {key => processed_children}}
  #   # => [{"/"=>[]}, {"/a"=>[{"/a/b"=>[{"/a/b/c"=>[]}]}, {"/a/d"=>[]}]}, {"/b"=>[]}]
  #
  def self.map_key_tree(tree, &blk)
    tree.map do |pair|
      key, children = pair
      blk.call(key, map_key_tree(children, &blk))
    end
  end

  #:nodoc:
  def self.value_tag(xm, h, tag)
    value = h[tag]
    xm.tag!(tag, value) unless value.blank?
  end

  #:nodoc:
  def self.list_tag(xm, collection, collection_tag, member_tag)
    unless collection.nil? or collection.empty?
      xm.tag!(collection_tag) do |xm|
        collection.each do |value|
          xm.tag!(member_tag, value)
        end
      end
    end
  end

  #
  # Produces the XML format, given an XML builder object and the resource tree.  Note that by design, the 
  # the generic #to_yaml and #to_json can be called on the tree directly.
  #
  def self.resource_xml(xm, tree)
    xm.Resources do |xm|
      tree.each do |resource|
        xm.Resource do |xm|
          value_tag(xm, resource, "rel")
          value_tag(xm, resource, "name")
          value_tag(xm, resource, "path_template")

          list_tag(xm, resource["params"], "Params", "param")
          list_tag(xm, resource["optional_params"], "OptionalParams", "param")

          # could use a list of elements here, but let's follow HTTP's lead and reduce the verbosity
          options = resource["options"] || []
          xm.options(options.join(", ")) unless options.empty?

          resources = resource["resources"] || []
          resource_xml(xm, resources) unless resources.empty?
        end
      end
    end
    xm
  end
end

if __FILE__ == $0
  paths = ["/", "/a", "/a/b", "/a/b/c", "/a/d", "/b"]
  puts DescribedRoutes::make_key_tree(paths){|possible_prefix, route|
    route[0...possible_prefix.length] == possible_prefix && possible_prefix != "/"
  }.inspect
  # => [["/", []], ["/a", [["/a/b", [["/a/b/c", []]]], ["/a/d", []]]], ["/b", []]]

  tree = [["/", []], ["/a", [["/a/b", [["/a/b/c", []]]], ["/a/d", []]]], ["/b", []]]
  puts DescribedRoutes::map_key_tree(tree){|key, processed_children| {key => processed_children}}.inspect  
  # => [{"/"=>[]}, {"/a"=>[{"/a/b"=>[{"/a/b/c"=>[]}]}, {"/a/d"=>[]}]}, {"/b"=>[]}]
end
