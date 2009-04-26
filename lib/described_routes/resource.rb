require "json"

module DescribedRoutes
  class Resource
    # The resource's name.  Optional.  Making these unique across the application is helpful for clients
    # that may wish to pick out nested routes by name.
    attr_reader :name
    
    # Optional attribute that describes a resource's relationship to its parent.  For example:
    # * a nested route to a resource's edit page would have rel of "edit"
    # * a nested collection of articles under a "user" resource would have have a rel of "articles"
    # Collection members generally don't need a rel as they are identified by their params
    attr_reader :rel
    
    # A template for generating paths relative to the application's base.
    attr_reader :path_template
    
    # The parameters required by the path template
    attr_reader :params
    
    # Optional paramaters that may be used by the template
    attr_reader :optional_params
    
    # "options" in the sense of the HTTP option request - i.e. a list of HTTP methods.  Optional.
    attr_reader :options
    
    # An optional list of nested resources
    attr_reader :resources
    
    # Initialize a Resource.  See the attribute descriptions above for explanations of the parameters.
    def initialize(name, rel, path_template, params, optional_params, options, resources)
      @name, @rel, @path_template, @params, @optional_params = name, rel, path_template, params, optional_params
      @options = options || []
      @resources = resources || []
    end
    
    # Create a Resource from its Hash representation
    def self.from_hash(hash)
      self.new(*%w(name, rel, path_template, params, optional_params, options, resources).map{|k| hash[k]})
    end
    
    # Convert to a hash (equivalent to its JSON or YAML representation)
    def to_hash
      hash = {}
      hash["name"] = name if name && !name.empty?
      hash["rel"] = rel if rel && !rel.empty?
      hash["path_template"] = path_template if path_template && !path_template.empty?

      hash["options"] = options if options && !options.empty?

      hashes = self.class.to_hashes(resources)
      hash["resources"] = hashes if hashes && !hashes.empty?
      
      hash
    end
    
    # Make a hash of child resources, keyed by rel
    def by_rel
      resources.inject({}) do |hash, resource|
        hash[resource.rel] = resource if resource.rel
      end
    end
    
    # Make a hash of child resources, keyed by params (sorted)
    def by_param_set
      resources.inject({}) do |hash, resource|
        hash[resource.params.sort] = resource if resource.params && !resource.rel
      end      
    end
  end
end

