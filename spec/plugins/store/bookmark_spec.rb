
require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'store/bookmark'

require 'pathname'

describe Automatic::Plugin::StoreBookmark do
  before do
    @db_filename = "test_bookmark.db"
    db_path = Pathname(__FILE__).parent+"../../../db/#{@db_filename}"
    db_path.delete if db_path.exist?
    Automatic::Plugin::StoreBookmark.new({"db" => @db_filename}).run
  end
  
  it "should store 1 record for the new link" do
    instance = Automatic::Plugin::StoreBookmark.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed { item "http://github.com" }
      })
    
    lambda {
      instance.run.should have(1).feed
    }.should change(Automatic::Plugin::Bookmark, :count).by(1)
  end

  it "should not store record for the existent link" do
    instance = Automatic::Plugin::StoreBookmark.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed { item "http://github.com" }
      })
    
    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Bookmark, :count).by(0)
  end
end

