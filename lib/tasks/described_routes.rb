require 'tasks/rails'
require 'described_routes/rails_routes'

namespace :described_routes do
  desc "Describe resource structure as a Ruby literal"
  desc "Describe resource structure in JSON format"

  task :json => :environment do
    puts DescribedRoutes::ResourceTemplate.to_json(
            DescribedRoutes::RailsRoutes.get_resource_templates)
  end

  desc "Describe resource structure in YAML format"
  task :yaml => :environment do
    puts DescribedRoutes::ResourceTemplate.to_yaml(
            DescribedRoutes::RailsRoutes.get_resource_templates)
  end

  desc "Describe resource structure in YAML format (basic structure only)"
  task :yaml_short => :environment do
    puts DescribedRoutes::ResourceTemplate.to_yaml(
            DescribedRoutes::RailsRoutes.get_resource_templates).grep(
                /(name|rel|path_template|uri_template|resources):|^---/)
  end

  desc "Describe resource structure in XML format"
  task :xml => :environment do
    puts DescribedRoutes::ResourceTemplate.to_xml(
             Builder::XmlMarkup.new(:indent => 2),
             DescribedRoutes::RailsRoutes.get_resource_templates
           ).target!
  end

  desc "Describe resource structure in text format"
  task :text => :environment do
    puts DescribedRoutes::ResourceTemplate.to_text(
            DescribedRoutes::RailsRoutes.get_resource_templates)
  end
  
  # unsupported, for testing
  task :ruby => :environment do
    puts DescribedRoutes::ResourceTemplate.to_parsed(
            DescribedRoutes::RailsRoutes.get_resource_templates).inspect
  end

  # unsupported
  task :get_rails_resources => :environment do
    puts DescribedRoutes::RailsRoutes.get_rails_resources.inspect
  end
  
  # unsupported
  task :get_parsed_rails_resources => :environment do
    puts DescribedRoutes::RailsRoutes.get_parsed_rails_resources.inspect
  end
end
