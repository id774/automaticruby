# -*- coding: utf-8 -*-
# Name::      Automatic::Spec
# Updated::   Sep 18, 2012

APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift APP_ROOT
$LOAD_PATH.unshift File.join(APP_ROOT)
$LOAD_PATH.unshift File.join(APP_ROOT, 'lib')
$LOAD_PATH.unshift File.join(APP_ROOT, 'plugins')

ENV["AUTOMATIC_RUBY_ENV"] ||= "test"
Bundler.require :test if defined?(Bundler)

if ENV['COVERAGE'] == 'on'
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

  SimpleCov.start do
    add_filter "spec"
    add_filter "vendor"
  end
end

require 'lib/automatic'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

unless /^1\.9\./ =~ RUBY_VERSION
  require 'rspec'
end

RSpec.configure do |config|
  config.mock_with :rspec
end

module AutomaticSpec
  class << self
    def generate_pipeline(&block)
      pipeline_generator = StubPipelineGenerator.new
      pipeline_generator.instance_eval(&block)
      pipeline_generator.pipeline
    end

    def root_dir
      File.join(__FILE__, "../../")
    end

    def db_dir
      dir = (File.expand_path('~/.automatic/db'))
      if File.directory?(dir)
        dir
      else
        File.join(root_dir, "db")
      end
    end
  end

  class StubPipelineGenerator
    attr_reader :pipeline

    def initialize
      @pipeline = []
    end

    def feed(&block)
      generator = StubFeedGenerator.new
      generator.instance_eval(&block)
      @pipeline << generator.feed
    end
  end

  class StubFeedGenerator
    def initialize
      @channel = RSS::Rss::Channel.new
    end

    def feed
      rss = RSS::Rss.new([])
      rss.instance_variable_set(:@channel, @channel)
      rss
    end

    def item(url, title="", description="", date="")
      i = RSS::Rss::Channel::Item.new
      i.link = url
      i.title = title unless title.blank?
      i.instance_variable_set(:@description, description)
      i.pubDate = date unless date.blank?
      @channel.items << i
    end
  end
end
