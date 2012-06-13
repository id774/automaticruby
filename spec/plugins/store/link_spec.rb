#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Link
# Author::    774 <http://id774.net>
# Created::   Jun 13, 2012
# Updated::   Jun 13, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'store/link'

require 'pathname'

describe Automatic::Plugin::StoreLink do
  before do
    @db_filename = "test_link.db"
    db_path = Pathname(AutomaticSpec.db_dir).cleanpath+"#{@db_filename}"
    db_path.delete if db_path.exist?
    Automatic::Plugin::StoreLink.new({"db" => @db_filename}).run
  end

  it "should store 14 record for the new link" do
    instance = Automatic::Plugin::StoreLink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        link "storeLink.html"
      }
    )

    lambda {
      instance.run.should have(14).feeds
    }.should change(Automatic::Plugin::Link, :count).by(14)
  end

  it "should not store record for the existent link" do
    instance = Automatic::Plugin::StoreLink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        link "storeLink2.html"
      }
    )

    instance.run.should have(15).feeds
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Link, :count).by(0)
  end
end
