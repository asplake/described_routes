require 'tasks/rails'
require 'described_routes/rake_task_methods'

namespace :described_routes do
  desc 'Describe resource structure in JSON format (optional: add "BASE=http://...")'
  task :json => :environment do
    puts DescribedRoutes::RakeTaskMethods.json
  end

  desc 'Describe resource structure in YAML format (optional: add "BASE=http://...")'
  task :yaml => :environment do
    puts DescribedRoutes::RakeTaskMethods.yaml
  end

  desc 'Describe resource structure in YAML format (basic structure only) (optional: add "BASE=http://...")'
  task :yaml_short => :environment do
    puts DescribedRoutes::RakeTaskMethods.yaml_short
  end

  desc 'Describe resource structure in XML format (optional: add "BASE=http://...")'
  task :xml => :environment do
    puts DescribedRoutes::RakeTaskMethods.xml
  end

  desc 'Describe resource structure in text format (optional: add "BASE=http://...")'
  task :text => :environment do
    puts DescribedRoutes::RakeTaskMethods.text
  end
  
  # unsupported
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
