# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::CustomFeed::SVNFLog
# Author::    kzgs
# Created::   Mar 4, 2012
# Updated::   Mar 4, 2012
# Copyright:: kzgs Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'store/target_link'

require 'tmpdir'
require 'pathname'

describe Automatic::Plugin::StoreTargetLink do
  it "should store the target link" do
    Dir.mktmpdir do |dir|
      instance = Automatic::Plugin::StoreTargetLink.new(
        { "path" => dir },
        AutomaticSpec.generate_pipeline {
          feed { item "http://digithoughts.com/rss" }
        })
      
      instance.run.should have(1).feed
      (Pathname(dir)+"rss").should be_exist
    end
  end
end
