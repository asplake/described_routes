require 'tasks/rails'
require 'described_routes'

namespace :described_routes do
  desc "Describe resource structure as a Ruby literal"
  task :ruby => :environment do
    puts DescribedRoutes::get_resource_tree.inspect
  end

  desc "Describe resource structure in JSON format"
  task :json => :environment do
    puts DescribedRoutes::get_resource_tree.to_json
  end

  desc "Describe resource structure in YAML format"
  task :yaml => :environment do
    puts DescribedRoutes::get_resource_tree.to_yaml
  end
  desc "Describe resource structure in YAML format (basic structure only)"
  task :yaml_short => :environment do
    puts DescribedRoutes::get_resource_tree.to_yaml.grep(/name|rel|path_template|resources/)
  end

  desc "Describe resource structure in XML format"
  task :xml => :environment do
    puts DescribedRoutes::resource_xml(
           Builder::XmlMarkup.new(:indent => 2),
           DescribedRoutes::get_resource_tree
         ).target!
  end
end
