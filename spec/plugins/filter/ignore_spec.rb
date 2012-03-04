require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/ignore'

describe Automatic::Plugin::FilterIgnore do
  context "with exclusion by title" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'title' => ["CD"],
        'title' => ["DVD"],
        'title' => ["LIVE"],
        'title' => ["HMV"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://id774.net/blog/feed/" }
          feed { item "http://www.hmv.co.jp/rss/news/top/1_100/" }
        })
    }
    
    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end

  context "with exclusion by description" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'description' => ["CD"],
        'description' => ["DVD"],
        'description' => ["LIVE"],
        'description' => ["HMV"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://id774.net/blog/feed/" }
          feed { item "http://www.hmv.co.jp/rss/news/top/1_100/" }
        })
    }
    
    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end

  context "with exclusion by link" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'link' => ["github"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }
    
    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end
end
