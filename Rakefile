# encoding: utf-8

require 'rubygems'

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ["-c"]
  spec.pattern = FileList['spec/**/*_spec.rb']
end

namespace :spec do
  desc "Run RSpec for plugins"
  RSpec::Core::RakeTask.new(:plugins) do |spec|
    spec.rspec_opts = ["-c"]
    spec.pattern = FileList['spec/plugins/**/*_spec.rb']
  end

  desc "Run RSpec for main procedure"
  RSpec::Core::RakeTask.new(:lib) do |spec|
    spec.rspec_opts = ["-c"]
    spec.pattern = FileList['spec/lib/**/*_spec.rb']
  end
end

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "automatic"
  gem.homepage = "http://github.com/id774/automaticruby"
  gem.license = "GPL"
  gem.summary = %Q{Automatic Ruby}
  gem.description = %Q{Ruby General Automation Framework}
  gem.email = "idnanashi@gmail.com"
  gem.authors = ["id774"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

if /^1\.9\./ =~ RUBY_VERSION
  desc "Run RSpec code examples with simplecov"
  task :simplecov do
    ENV['COVERAGE'] = "on"
    Rake::Task[:spec].invoke
  end
else
  desc "Run RSpec code examples with rcov"
  RSpec::Core::RakeTask.new(:rcov) do |spec|
    spec.pattern = FileList['spec/**/*_spec.rb']
    exclude_files = [
      "gems",
    ]
    spec.rcov_opts = ['--exclude', exclude_files.join(",")]
    spec.rcov = true
  end
end
