$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'plugins'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

Bundler.require :test if defined?(Bundler)

if ENV['COVERAGE'] == 'on'
  require 'simplecov'
  SimpleCov.start
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
      return pipeline_generator.feeds
    end
  end

  class StubPipelineGenerator
    attr_reader :feeds
    
    def initialize
      @feeds = []
    end
    
    def feed(&block)
      feed_generator = StubFeedGenerator.new
      feed_generator.instance_eval(&block)
      @feeds << feed_generator.feed
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

    def item(url, title="")
      itm = RSS::Rss::Channel::Item.new
      itm.link = url
      itm.title = title unless title.blank?
      @channel.items << itm
    end
  end
end

