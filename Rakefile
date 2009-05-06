%w[rubygems rake rake/clean fileutils newgem rubigen].each { |f| require f }
$:.push File.dirname(__FILE__) + '/lib'
require 'described_routes'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.new('described_routes', DescribedRoutes::VERSION) do |p|
  p.developer('Mike Burrows', 'mjb@asplake.co.uk')
  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  p.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  p.rubyforge_name       = 'describedroutes'
  p.url = 'http://positiveincline.com/?p=213'
  # p.extra_deps         = [
  #   ['activesupport','>= 2.0.2'],
  # ]
  p.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  
  p.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
  p.rsync_args = '-av --delete --ignore-errors'
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
  Dir.chdir("test_rails_app"){ sh "rake log:clear tmp:clear" }
end
