# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::FullText
# Author::    774 <http://id774.net>
# Updated::   Jun 14, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'store/full_text'

require 'pathname'

describe Automatic::Plugin::StoreFullText do
  before do
    @db_filename = "test_full_text.db"
    db_path = Pathname(AutomaticSpec.db_dir).cleanpath+"#{@db_filename}"
    db_path.delete if db_path.exist?
    Automatic::Plugin::StoreFullText.new({"db" => @db_filename}).run
  end

  it "should store 1 record for the new blog entry" do
    instance = Automatic::Plugin::StoreFullText.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed { item "http://blog.id774.net/blogs/feed/" }
      }
    )

    lambda {
      instance.run.should have(1).feed
    }.should change(Automatic::Plugin::Blog, :count).by(1)
  end

  it "should not store record for the existent blog entry" do
    instance = Automatic::Plugin::StoreFullText.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed { item "http://blog.id774.net/blogs/feed/" }
      }
    )

    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Blog, :count).by(0)
  end

end
