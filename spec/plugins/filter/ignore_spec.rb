require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/ignore'


def generate_pipeline(&block)
  pipeline_generator = StubPipelineGenerator.new
  pipeline_generator.instance_eval(&block)
  return pipeline_generator.feeds
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

  class StubFeedGenerator
    def initialize
      @channel = RSS::Rss::Channel.new
    end
    
    def feed
      rss = RSS::Rss.new([])
      rss.instance_variable_set(:@channel, @channel)
      return rss
    end

    def add_link(url)
      item = RSS::Rss::Channel::Item.new
      item.link = url
      @channel.items << item
    end
  end
end

describe Automatic::Plugin::FilterIgnore do
  context "with invalid argument for #initialize" do
    context "empty config" do
      subject { Automatic::Plugin::FilterIgnore.new({}) }
      
      specify {
        lambda { subject.exclude("") }.should raise_exception(
          NoMethodError, /undefined method `each'/)
      }
    end
  end
  
  context "with empty exclusion target" do
    subject {
      Automatic::Plugin::FilterIgnore.new({'exclude' => []}, 
        generate_pipeline {
          feed { add_link "http://github.com" }
        })
    }
      
    describe "#exclude" do
      context "for empty link" do
        specify {
          subject.exclude("").should be_false
        }
      end
      
      context "for existent link" do
        specify {
          subject.exclude("http://github.com").should be_false
        }
      end
    end

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end  
  
  context "with exclusion target 'github'" do
    subject {
      Automatic::Plugin::FilterIgnore.new({'exclude' => ["github"]},
        generate_pipeline {
          feed { add_link "http://github.com" }
          feed { add_link "http://google.com" }
        })
    }
    
    describe "#exclude" do
      context "for empty link" do
        specify {
          subject.exclude("").should be_false
        }
      end
      
      context "for the link including exclusion targed" do
        specify {
          subject.exclude("http://github.com").should be_true
        }
      end
    end

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end  
end
