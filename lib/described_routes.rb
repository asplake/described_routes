require 'described_routes/resource'

module DescribedRoutes
  # rubygem version
  VERSION = "0.0.2"
  
  # Convert an array of Resource objects to array of hashes equivalent to their JSON or YAML representations
  def self.to_parsed(resources)
    resources.map{|resource| resource.to_hash}
  end
  
  # Convert an array of Resource objects to JSON
  def self.to_json(resources)
    self.to_parsed(resources).to_json
  end
  
  # Convert an array of Resource objects to YAML
  def self.to_yaml(resources)
    self.to_parsed(resources).to_yaml
  end
  
  # Create an array of Resource objects from a JSON string
  def self.parse_json(json)
    self.from_parsed(JSON.parse(json))
  end
  
  # Create an array of Resource objects from a JSON string
  def self.parse_yaml(yaml)
    self.from_parsed(YAML::load(yaml))
  end

  # Create an array of Resource objects from an array of hashes
  def self.from_parsed(parsed)
    raise ArgumentError.new("not an array") unless parsed.kind_of?(Array)

    parsed.map do |hash|
      DescribedRoute.from_hash(hash)
    end
  end

  #
  # Produces the XML format, given an XML builder object and an array of Resource objects
  #
  def self.to_xml(xm, resources)
    xm.Resources do |xm|
      resources.each do |resource|
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
          to_xml(xm, resources) unless resources.empty?
        end
      end
    end
    xm
  end

  def self.value_tag(xm, h, tag) #:nodoc:
    value = h[tag]
    xm.tag!(tag, value) unless value.blank?
  end

  def self.list_tag(xm, collection, collection_tag, member_tag) #:nodoc:
    unless collection.nil? or collection.empty?
      xm.tag!(collection_tag) do |xm|
        collection.each do |value|
          xm.tag!(member_tag, value)
        end
      end
    end
  end
  
  # Get a hash of all named resources contained in the supplied collection, keyed by resource name
  def all_by_name(resources, h = {})
    resources.inject(h) do |hash, resource|
      hash[resource.name] = resource if resource.name
      all_by_name(resource.resource, named)
    end
  end
end
