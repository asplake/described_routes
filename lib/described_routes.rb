require 'described_routes/resource_template'

module DescribedRoutes
  # rubygem version
  VERSION = "0.1.0"
  
  # Convert an array of ResourceTemplate objects to array of hashes equivalent to their JSON or YAML representations
  def self.to_parsed(resource_templates)
    resource_templates.map{|resource_template| resource_template.to_hash}
  end
  
  # Convert an array of ResourceTemplate objects to JSON
  def self.to_json(resource_templates)
    self.to_parsed(resource_templates).to_json
  end
  
  # Convert an array of ResourceTemplate objects to YAML
  def self.to_yaml(resource_templates)
    self.to_parsed(resource_templates).to_yaml
  end
  
  # Create an array of ResourceTemplate objects from a JSON string
  def self.parse_json(json)
    self.from_parsed(JSON.parse(json))
  end
  
  # Create an array of ResourceTemplate objects from a JSON string
  def self.parse_yaml(yaml)
    self.from_parsed(YAML::load(yaml))
  end

  # Create an array of ResourceTemplate objects from an array of hashes
  def self.from_parsed(parsed)
    raise ArgumentError.new("not an array") unless parsed.kind_of?(Array)

    parsed.map do |hash|
      ResourceTemplate.from_hash(hash)
    end
  end

  #
  # Produces the XML format, given an XML builder object and an array of ResourceTemplate objects
  #
  def self.to_xml(xm, resource_templates)
    xm.ResourceTemplates do |xm|
      resource_templates.each do |resource_template|
        xm.ResourceTemplate do |xm|
          value_tag(xm, resource_template, "rel")
          value_tag(xm, resource_template, "name")
          value_tag(xm, resource_template, "path_template")
          value_tag(xm, resource_template, "uri_template")

          list_tag(xm, resource_template["params"], "Params", "param")
          list_tag(xm, resource_template["optional_params"], "OptionalParams", "param")

          # could use a list of elements here, but let's follow HTTP's lead and reduce the verbosity
          options = resource_template["options"] || []
          xm.options(options.join(", ")) unless options.empty?

          resource_templates = resource_template["resource_templates"] || []
          to_xml(xm, resource_templates) unless resource_templates.empty?
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
  
  # Get a hash of all named ResourceTemplate objects contained in the supplied collection, keyed by name
  def self.all_by_name(resource_templates, h = {})
    resource_templates.inject(h) do |hash, resource_template|
      hash[resource_template.name] = resource_template if resource_template.name
      all_by_name(resource_template.resource_templates, hash)
      hash
    end
    h
  end
end
