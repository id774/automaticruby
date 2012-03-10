# -*- coding: utf-8 -*-
# Name::      pipeline_sepc.rb
# Author::    ainame
# Created::   Mar 10, 2012
# Updated::   Mar 10, 2012
# Copyright:: ainame Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.join(File.dirname(__FILE__) ,'../../spec_helper'))
require 'automatic'
require 'automatic/pipeline'

TEST_MODULES = ["SubscriptionFeed", "FilterIgnore"]

describe Automatic::Pipeline do 
  describe "in default dir" do 
    before do 
      Automatic.root_dir = APP_ROOT
      Automatic.user_dir = nil
    end
    
    describe "#load_plugin" do
      it "raise no plugin error" do 
        lambda{ 
          Automatic::Plugin.load_plugin "FooBar"
        }.should raise_exception
      end

      it "correctly load module" do 
        TEST_MODULES.each do |mod|
          Automatic::Pipeline.load_plugin mod.to_s
          Automatic::Plugin.const_get(mod).class.should == Class
        end
      end
    end
  end

  describe "in user dir" do 
    before do 
      Automatic.root_dir = APP_ROOT
      Automatic.user_dir = File.join(APP_ROOT, "spec/user_dir")
    end

    describe "#load_plugin" do
      it "correctly load module" do 
        # StoreMock is the mock class that it return pipeline.
        mock = "StoreMock"
        Automatic::Pipeline.load_plugin mock
        klass = Automatic::Plugin.const_get(mock)
        klass.class.should == Class
        klass.new(nil, ["mock"]).run.should == "mock"
      end
    end
  end
end
