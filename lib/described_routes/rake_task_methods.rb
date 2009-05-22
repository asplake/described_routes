require 'described_routes/rails_routes'

module DescribedRoutes
  module RakeTaskMethods
    # Describe resource structure in JSON format
    def self.json
      get_routes.to_json
    end

    # "Describe resource structure in YAML format
    def self.yaml
      get_routes.to_yaml
    end

    # Describe resource structure in XML format
    def self.xml
      get_routes.to_xml(Builder::XmlMarkup.new(:indent => 2)).target!
    end

    # Describe resource structure in text format
    def self.text
      get_routes.to_text
    end

    # Gets the application's routes
    def self.get_routes
      DescribedRoutes::RailsRoutes.get_resource_templates(ENV['BASE'])
    end
  end
end