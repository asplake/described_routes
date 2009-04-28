require 'tasks/rails'
require 'described_routes/rails_routes'

namespace :described_routes do
  desc "Describe resource structure as a Ruby literal"
  desc "Describe resource structure in JSON format"

  task :json => :environment do
    puts DescribedRoutes::RailsRoutes.get_resources.to_json
  end

  desc "Describe resource structure in YAML format"
  task :yaml => :environment do
    puts DescribedRoutes::RailsRoutes.get_resources.to_yaml
  end

  desc "Describe resource structure in YAML format (basic structure only)"
  task :yaml_short => :environment do
    puts DescribedRoutes::RailsRoutes.get_resources.to_yaml.grep(/(name|rel|path_template|uri_template|resources):|^---/)
  end

  desc "Describe resource structure in XML format"
  task :xml => :environment do
    puts DescribedRoutes::to_xml(
           Builder::XmlMarkup.new(:indent => 2),
           DescribedRoutes::RailsRoutes.get_resources
         ).target!
  end
end
