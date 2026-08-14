# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Store::File
# Author:       kzgs
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar  4, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'store/file'
require 'tmpdir'
require 'pathname'

describe Automatic::Plugin::StoreFile do
  it "should store the target link", :network do
    Dir.mktmpdir do |dir|
      instance = Automatic::Plugin::StoreFile.new(
        { "path" => dir },
        AutomaticSpec.generate_pipeline {
          feed { item "http://id774.net/test/store/rss" }
        }
      )
      instance.run.should have(1).feed
      (Pathname(dir)+"rss").should be_exist
    end
  end

  it "should error during file download" do
    Dir.mktmpdir do |dir|
      instance = Automatic::Plugin::StoreFile.new(
        { "path" => dir },
        AutomaticSpec.generate_pipeline {
          feed { item "aaa" }
        }
      )
      instance.run.should have(0).feed
    end
  end

  it "should error and retry during file download" do
    Dir.mktmpdir do |dir|
      instance = Automatic::Plugin::StoreFile.new(
        {
          "path" => dir,
          'retry' => 1,
          'interval' => 2
        },
        AutomaticSpec.generate_pipeline {
          feed { item "aaa" }
        }
      )
      instance.run.should have(0).feed
    end
  end

end
