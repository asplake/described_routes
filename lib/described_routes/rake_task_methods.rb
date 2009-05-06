require 'described_routes/rails_routes'

module DescribedRoutes
  module RakeTaskMethods
    # Describe resource structure in JSON format
    def self.json
      DescribedRoutes::ResourceTemplate.to_json(
              DescribedRoutes::RailsRoutes.get_resource_templates(ENV['BASE']))
    end

    # "Describe resource structure in YAML format
    def self.yaml
      DescribedRoutes::ResourceTemplate.to_yaml(
              DescribedRoutes::RailsRoutes.get_resource_templates(ENV['BASE']))
    end

    # Describe resource structure in YAML format (basic structure only)
    def self.yaml_short
      DescribedRoutes::ResourceTemplate.to_yaml(
              DescribedRoutes::RailsRoutes.get_resource_templates(ENV['BASE'])).grep(
                  /(name|rel|path_template|uri_template|resources):|^---/).join
    end

    # Describe resource structure in XML format
    def self.xml
      DescribedRoutes::ResourceTemplate.to_xml(
               Builder::XmlMarkup.new(:indent => 2),
               DescribedRoutes::RailsRoutes.get_resource_templates(ENV['BASE'])
             ).target!
    end

    # Describe resource structure in text format
    def self.text
      DescribedRoutes::ResourceTemplate.to_text(
              DescribedRoutes::RailsRoutes.get_resource_templates(ENV['BASE']))
    end
  end
end