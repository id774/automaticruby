# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Target
# Author::    774 <http://id774.net>
# Created::   Jun 13, 2012
# Updated::   Jun 13, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'store/target'

require 'tmpdir'
require 'pathname'

describe Automatic::Plugin::StoreTarget do
  it "should store the target link" do
    Dir.mktmpdir do |dir|
      instance = Automatic::Plugin::StoreTarget.new(
        { "path" => dir },
        AutomaticSpec.generate_pipeline {
          link "storeTarget.html"
        }
      )
      instance.run.should have(1).item
      (Pathname(dir)+"Eila_omote.jpg").should be_exist
    end
  end

  it "should error during file download" do
    Dir.mktmpdir do |dir|
      instance = Automatic::Plugin::StoreTarget.new(
        { "path" => dir },
        AutomaticSpec.generate_pipeline {
          link "storeTarget2.html"
        }
      )
      instance.run.should have(1).items
    end
  end
end
