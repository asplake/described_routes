require "json"

module DescribedRoutes
  class ResourceTemplate
    # The template's name.  Optional.  Making these unique across the application is helpful for clients
    # that may wish to pick out nested templates by name.
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
    
    # Optional paramaters that may be used by the path template
    attr_reader :optional_params
    
    # "options" in the sense of the HTTP option request - i.e. a list of HTTP methods.  Optional.
    attr_reader :options
    
    # An optional list of nested resource templates
    attr_reader :resource_templates
    
    # Initialize a ResourceTemplate.  See the attribute descriptions above for explanations of the parameters.
    def initialize(name, rel, path_template, params, optional_params, options, resource_templates)
      @name, @rel, @path_template = name, rel, path_template
      @params = params || []
      @optional_params = optional_params || []
      @options = options || []
      @resource_templates = resource_templates || []
    end
    
    # Create a ResourceTemplate from its Hash representation
    def self.from_hash(hash)
      attributes = %w(name rel path_template params optional_params options).map{|k| hash[k]}
      if hash["resource_templates"]
        attributes << hash["resource_templates"].map{|h| from_hash(h)} if hash["resource_templates"]
      else
        attributes << nil
      end
      self.new(*attributes)
    end
    
    # Convert to a hash (equivalent to its JSON or YAML representation)
    def to_hash
      hash = {}
      hash["name"] = name if name && !name.empty?
      hash["rel"] = rel if rel && !rel.empty?
      hash["path_template"] = path_template if path_template && !path_template.empty?

      hash["options"] = options if options && !options.empty?

      hashes = DescribedRoutes.to_parsed(resource_templates)
      hash["resource_templates"] = hashes if hashes && !hashes.empty?
      
      hash
    end
  end
end

