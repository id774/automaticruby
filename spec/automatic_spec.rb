# -*- coding: utf-8 -*-
# Name::      Automatic
# Author::    kzgs
# Created::   Mar 9, 2012
# Updated::   Mar 9, 2012
# Copyright:: kzgs Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'automatic'

describe Automatic do
  describe "#run" do
    describe "with a root dir which has default recipe" do
      specify {
        lambda {
          Automatic.run(File.dirname(__FILE__))
        }.should raise_exception(Errno::ENOENT)
      }
    end

    specify {
      root_dir = File.dirname(__FILE__)+"/.."
      $LOAD_PATH << root_dir+"/plugins"
      require 'subscription/feed'
      require 'filter/ignore'
      require 'store/permalink'
      require 'publish/hatena_bookmark'
      lambda {
        Automatic.run(root_dir)
      }.should_not raise_exception
    }
  end
end

