
require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'store/permalink'

require 'pathname'

describe Automatic::Plugin::StorePermalink do
  before do
    @db_filename = "test_permalink.db"
    db_path = Pathname(AutomaticSpec.db_dir).cleanpath+"#{@db_filename}"
    db_path.delete if db_path.exist?
    Automatic::Plugin::StorePermalink.new({"db" => @db_filename}).run
  end

  it "should store 1 record for the new link" do
    instance = Automatic::Plugin::StorePermalink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed { item "http://github.com" }
      })
    
    lambda {
      instance.run.should have(1).feed
    }.should change(Automatic::Plugin::Permalink, :count).by(1)
  end

  it "should not store record for the existent link" do
    instance = Automatic::Plugin::StorePermalink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed { item "http://github.com" }
      })

    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Permalink, :count).by(0)
  end
end

