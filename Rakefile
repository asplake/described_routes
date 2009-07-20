%w[rubygems rake rake/clean fileutils newgem rubigen].each { |f| require f }
$:.push File.dirname(__FILE__) + '/lib'
require 'described_routes'
require 'hoe'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'described_routes' do
  developer('Mike Burrows', 'mjb@asplake.co.uk')
  self.readme_file          = "README.rdoc"
  self.changes              = paragraphs_of("History.txt", 0..1).join("\n\n")
  self.rubyforge_name       = 'describedroutes'
  self.url = 'http://positiveincline.com/?p=213'
  self.extra_deps         = [
    ['addressable','>= 2.1.0'],
  ]
  self.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  
  self.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (rubyforge_name == name) ? rubyforge_name : "\#{rubyforge_name}/\#{name}"
  self.remote_rdoc_dir = File.join(path.gsub(/^#{rubyforge_name}\/?/,''), 'rdoc')
  self.rsync_args = '-av --delete --ignore-errors'
end

task :info do
  puts "version=#{DescribedRoutes::VERSION}"
  [:description, :summary, :changes, :author, :url].each do |attr|
    puts "#{attr}=#{$hoe.send(attr)}\n"
  end
end

require 'newgem/tasks' # load /tasks/*.rake
Dir['tasks/**/*.rake'].each { |t| load t }

#
# These add to existing tasks and execute in the ./test_rails_app/ subproject
#

task :test do
  rubyopt = "-I#{File.dirname(__FILE__) + '/lib'} #{ENV['RUBYOPT']}"
  Dir.chdir("test_rails_app"){ sh "RUBYOPT=\"#{rubyopt}\" rake test:integration" }
end

task :clean do
  rubyopt = "-I#{File.dirname(__FILE__) + '/lib'} #{ENV['RUBYOPT']}"
  Dir.chdir("test_rails_app"){ sh "RUBYOPT=\"#{rubyopt}\" rake log:clear tmp:clear" }
end
