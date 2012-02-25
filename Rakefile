# encoding: utf-8

require 'rubygems'

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ["-c"]
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  exclude_files = [
    "gems",
    "spec"
  ]
  spec.rcov_opts = ['--exclude', exclude_files.join(",")]
  spec.rcov = true
end
