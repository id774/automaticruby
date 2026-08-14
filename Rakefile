# -*- mode: ruby; coding: utf-8 -*-
# Name::      Rakefile
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Feb 18, 2012
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# Test tasks only. This is not a build system, and the Jeweler and rcov tasks
# that used to live here have been removed; see doc/POLICY.md section 9.4.

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ['--color']
  spec.pattern = FileList['spec/**/*_spec.rb']
end

namespace :spec do
  desc 'Run the framework specs'
  RSpec::Core::RakeTask.new(:lib) do |spec|
    spec.rspec_opts = ['--color']
    spec.pattern = FileList['spec/lib/**/*_spec.rb']
  end

  desc 'Run the plugin specs'
  RSpec::Core::RakeTask.new(:plugins) do |spec|
    spec.rspec_opts = ['--color']
    spec.pattern = FileList['spec/plugins/**/*_spec.rb']
  end
end

desc 'Run the specs with SimpleCov coverage reporting'
task :coverage do
  ENV['COVERAGE'] = 'on'
  Rake::Task[:spec].invoke
end

task default: :spec
