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
      return pipeline_generator.pipeline
    end

    def root_dir
      return File.join(__FILE__, "../../")
    end

    def db_dir
      return File.join(root_dir, "db")
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

    def html(fixture)
      obj = File.read(File.join(File.dirname(__FILE__),
        "fixtures", fixture))
      @pipeline << obj
    end

    def link(fixture)
      obj = File.read(File.join(File.dirname(__FILE__),
        "fixtures", fixture))
      require 'extract/link'
      pipeline << obj
      @pipeline = []
      @pipeline << Automatic::Plugin::ExtractLink.new(nil, pipeline).run
    end
  end

  class StubFeedGenerator
    def initialize
      @channel = RSS::Rss::Channel.new
    end

    def feed
      rss = RSS::Rss.new([])
      rss.instance_variable_set(:@channel, @channel)
      return rss
    end

    def item(url, title="", description="", date="")
      itm = RSS::Rss::Channel::Item.new
      itm.link = url
      itm.title = title unless title.blank?
      itm.instance_variable_set(:@description, description)
      itm.pubDate = date unless date.blank?
      @channel.items << itm
    end
  end
end
