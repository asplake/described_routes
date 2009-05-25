require "json"
require "addressable/template"

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
  
  # Nested resource templates, a Resources object
  attr_reader :resource_templates
  
  #
  # Initialize a ResourceTemplate from a hash.  For example:
  #
  #   user_articles = ResourceTemplate.new(
  #                       "name"               => "user_articles",
  #                       "rel"                => "articles",
  #                       "uri_template"       => "http://example.com/users/{user_id}/articles{-prefix|.|format}",
  #                       "path_template"      => "/users/{user_id}/articles{-prefix|.|format}",
  #                       "params"             => ["user_id"],
  #                       "optional_params"    => ["format"],
  #                       "resource_templates" => [user_article, new_user_article])
  #
  # <code>resource_templates</code> (if provided) can be a ResourceTemplates object, an array of ResourceTemplate objects
  # or an array of hashes.  This last option makes it easy to initialize a whole hierarchy directly from deserialised JSON or YAML
  # objects, e.g.:
  #
  #   user_articles = ResourceTemplate.new(JSON.parse(json))
  #   user_articles = ResourceTemplate.new(YAML.load(yaml))
  #
  def initialize(hash={})
    @name, @rel, @uri_template, @path_template = %w(name rel uri_template path_template).map{|attr| hash[attr]}
    @params, @optional_params, @options = %w(params optional_params options).map{|attr| hash[attr] || []}
    @resource_templates = ResourceTemplates.new(hash["resource_templates"])
  end
  
  # Convert to a hash (equivalent to its JSON or YAML representation)
  def to_hash
    hash = {}
    
    hash["name"] = name if name && !name.empty?
    hash["rel"] = rel if rel && !rel.empty?
    hash["uri_template"] = uri_template if uri_template && !uri_template.empty?
    hash["path_template"] = path_template if path_template && !path_template.empty?

    hash["params"] = params if params && !params.empty?
    hash["optional_params"] = optional_params if optional_params && !optional_params.empty?
    hash["options"] = options if options && !options.empty?

    hash["resource_templates"] = resource_templates.to_parsed if !resource_templates.empty?
    
    hash
  end
  
  # Convert to JSON
  def to_json
    to_hash.to_json
  end

  # Convert to YAML
  def to_yaml
    to_hash.to_yaml
  end
  
  # Text report
  def to_text
    ResourceTemplates.new([self]).to_text
  end
  
  #
  # Produces the XML format, given an XML builder object and an array of ResourceTemplate objects
  #
  def to_xml(xm)
    xm.ResourceTemplate do |xm|
      value_tag(xm, "rel")
      value_tag(xm, "name")
      value_tag(xm, "path_template")
      value_tag(xm, "uri_template")

      list_tag(xm, params, "Params", "param")
      list_tag(xm, optional_params, "OptionalParams", "param")

      # could use a list of elements here, but let's follow HTTP's lead and reduce the verbosity
      xm.options(options.join(", ")) unless options.empty?

      resource_templates.to_xml(xm) unless resource_templates.empty?
    end
    xm
  end

  def value_tag(xm, tag) #:nodoc:
    value = self.send(tag.to_sym)
    xm.tag!(tag, value) unless value.blank?
  end

  def list_tag(xm, collection, collection_tag, member_tag) #:nodoc:
    unless collection.nil? or collection.empty?
      xm.tag!(collection_tag) do |xm|
        collection.each do |value|
          xm.tag!(member_tag, value)
        end
      end
    end
  end

  # Returns params and any optional_params in order, removing the parent's params
  def positional_params(parent)
    all_params = params + optional_params
    if parent
      all_params - parent.params
    else
      all_params
    end
  end
  
  # Returns this template's URI template, or one constructed from the given base and path template.
  def uri_template(base=nil)
    if @uri_template
      @uri_template
    elsif base && path_template
      base + path_template
    end
  end
  
  # Returns an expanded URI template with template variables filled from the given params hash.
  # Raises ArgumentError if params doesn't contain all mandatory params.
  def uri_for(params_hash, base=nil)
    missing_params = params - params_hash.keys
    unless missing_params.empty?
      raise ArgumentError.new("missing params #{missing_params.join(', ')}")
    end
    
    t = uri_template(base)
    unless t
      raise RuntimeError.new("uri_template(#{base.inspect})=nil; path_template=#{path_template.inspect}")
    end
    
    Addressable::Template.new(t).expand(params_hash).to_s
  end
  
  # Returns an expanded path template with template variables filled from the given params hash.
  # Raises ArgumentError if params doesn't contain all mandatory params, and a RuntimeError if there is no path_template.
  def path_for(params_hash)
    missing_params = params - params_hash.keys
    raise ArgumentError.new("missing params #{missing_params.join(', ')}") unless missing_params.empty?
    raise RuntimeError.new("#path_for called on resource template #{name.inspect} that has no path_template") if path_template.nil?
    Addressable::Template.new(path_template).expand(params_hash).to_s
  end
  
  # Return a new resource template with the path_template or uri_template partially expanded with the given params
  def partial_expand(actual_params)
    self.class.new(
        "name"               => name,
        "rel"                => rel,
        "uri_template"       => partial_expand_uri_template(uri_template, actual_params),
        "path_template"      => partial_expand_uri_template(path_template, actual_params),
        "params"             => params - actual_params.keys,
        "optional_params"    => optional_params - actual_params.keys,
        "options"            => options,
        "resource_templates" => resource_templates.partial_expand(actual_params))
  end
  
  # Partially expand a URI template
  def partial_expand_uri_template(template, params)#:nodoc:
    template && Addressable::Template.new(template).partial_expand(params).pattern
  end
  
  # Find member ResourceTemplate objects with the given rel
  def find_by_rel(rel)
    resource_templates.select{|resource_template| resource_template.rel == rel}
  end
  
  class ResourceTemplates < Array
    # Initialize Resources (i.e. a new collection of ResourceTemplate objects) from given collection of ResourceTemplates or hashes
    def initialize(collection=[])
      if collection
        raise ArgumentError.new("#{collection.inspect} is not a collection") unless collection.kind_of?(Enumerable)

        collection.each do |r|
          if r.kind_of?(ResourceTemplate)
            push(r)
          elsif r.kind_of?(Hash)
            push(ResourceTemplate.new(r))
          else
            raise ArgumentError.new("#{r.inspect} is neither a ResourceTemplate nor a Hash")
          end
        end
      end
    end

    # Create Resources from an XML string
    def self.parse_xml
      raise NotImplementedError.new
    end

    # Convert member ResourceTemplate objects to array of hashes equivalent to their JSON or YAML representations
    def to_parsed
      map {|resource_template| resource_template.to_hash}
    end

    # Convert an array of ResourceTemplate objects to JSON
    def to_json
      to_parsed.to_json
    end

    # Convert an array of ResourceTemplate objects to YAML
    def to_yaml
      to_parsed.to_yaml
    end

    #
    # Produces the XML format, given an XML builder object and an array of ResourceTemplate objects
    #
    def to_xml(xm)
      xm.ResourceTemplates do |xm|
        each do |resource_template|
          resource_template.to_xml(xm)
        end
      end
      xm
    end
    
    # Get a hash of all named ResourceTemplate objects contained in the supplied collection, keyed by name
    def all_by_name(h = {})
      inject(h) do |hash, resource_template|
        hash[resource_template.name] = resource_template if resource_template.name
        resource_template.resource_templates.all_by_name(hash)
        hash
      end
      h
    end
  
    # for #to_text
    def to_table(parent_template = nil, t = [], indent = '')
      inject(t) do |table, resource_template|
        if parent_template
          link = (resource_template.rel || '')
          new_params = resource_template.params - parent_template.params
        else
          link = resource_template.name
          new_params = resource_template.params
        end
        link += new_params.map{|p| "{#{p}}"}.join(', ')
        table << [
          indent + link,
          resource_template.name || '',
          resource_template.options.join(', '),
          resource_template.uri_template || resource_template.path_template
        ] 
        resource_template.resource_templates.to_table(resource_template, t, indent + '  ')
      end
      t
    end
  
    # text report
    def to_text
      table = self.to_table
    
      0.upto(2) do |i|
        width = table.map{|row| row[i].length}.max
        table.each do |row|
          row[i] = row[i].ljust(width)
        end
      end
    
      table.map{|row| row.join(' ')}.join("\n") + "\n"
    end
  
    # Partially expand the path_template or uri_template of the given resource templates with the given params,
    # returning new resource templates
    def partial_expand(actual_params)
      self.class.new(map{|resource_template| resource_template.partial_expand(actual_params)})
    end
  end
end