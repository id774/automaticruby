# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::FullText
# Author::    774 <http://id774.net>
# Updated::   Oct 15, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'store/full_text'
require 'pathname'

describe Automatic::Plugin::StoreFullText do
  before do
    @db_filename = "test_full_text.db"
    db_path = Pathname(AutomaticSpec.db_dir).cleanpath+"#{@db_filename}"
    db_path.delete if db_path.exist?
    tmp_out = StringIO.new()
    $stdout = tmp_out
    Automatic::Plugin::StoreFullText.new({"db" => @db_filename}).run
    $stdout = STDOUT
    tmp_out.rewind()
    Automatic::Log.puts("info", tmp_out.read())
  end

  it "should store 1 record for the new blog entry" do
    instance = Automatic::Plugin::StoreFullText.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed {
          item "http://blog.id774.net/blogs/feed/",
          "dummy title",
          "aaa bbb ccc http://test2.id774.net ddd eee",
          "Mon, 07 Mar 2011 15:54:11 +0900"
        }
      }
    )

    Automatic::Plugin::Blog.count.should eq 0
    lambda {
      instance.run.should have(1).feed
    }.should change(Automatic::Plugin::Blog, :count).by(1)
    Automatic::Plugin::Blog.count.should eq 1
  end

  it "should not store record for the existent blog entry" do
    instance = Automatic::Plugin::StoreFullText.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed { item "http://blog.id774.net/blogs/feed/" }
      }
    )

    Automatic::Plugin::Blog.count.should eq 0
    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Blog, :count).by(0)
    instance.run.should have(0).feed
    Automatic::Plugin::Blog.count.should eq 1
  end

  it "should not store record for the existent blog link" do
    instance = Automatic::Plugin::StoreFullText.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed {
          item "http://blog.id774.net/post/100",
          "#{rand(10000000)}",
          "aaa bbb ccc http://test2.id774.net ddd eee",
          "Mon, 07 Mar 2011 15:54:11 +0900"
        }
      }
    )

    Automatic::Plugin::Blog.count.should eq 0
    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Blog, :count).by(0)
    instance.run.should have(0).feed
    Automatic::Plugin::Blog.count.should eq 1
  end

  it "should not store record for the existent blog title" do
    instance = Automatic::Plugin::StoreFullText.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed {
          item "http://blog.id774.net/post/#{rand(1000000)}",
          "dummy",
          "aaa bbb ccc http://test2.id774.net ddd eee",
          "Mon, 07 Mar 2011 15:54:11 +0900"
        }
      }
    )

    Automatic::Plugin::Blog.count.should eq 0
    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Blog, :count).by(0)
    instance.run.should have(0).feed
    Automatic::Plugin::Blog.count.should eq 1
  end

end
