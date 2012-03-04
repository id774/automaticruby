require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/ignore'

describe Automatic::Plugin::FilterIgnore do
  context "with exclusion by description" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'description' => ["comment"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }
    
    describe "#run" do
      its(:run) { should have(2).feeds }
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
