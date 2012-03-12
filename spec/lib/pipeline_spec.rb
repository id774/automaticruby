# -*- coding: utf-8 -*-
# Name::      pipeline_sepc.rb
# Author::    ainame
# Created::   Mar 10, 2012
# Updated::   Mar 10, 2012
# Copyright:: ainame Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.join(File.dirname(__FILE__) ,'../spec_helper'))
require 'automatic'
require 'automatic/pipeline'

TEST_MODULES = ["SubscriptionFeed", "FilterIgnore"] if TEST_MODULES.nil?

describe Automatic::Pipeline do 
  describe "in default dir" do 
    before do 
      Automatic.root_dir = File.expand_path(File.join(File.dirname(__FILE__), "../../"))
      Automatic.user_dir = nil
    end
    
    describe "#load_plugin" do
      it "raise no plugin error" do 
        lambda{ 
          Automatic::Pipeline.load_plugin "FooBar"
        }.should raise_exception(Automatic::NoPluginError,
          /unknown plugin named FooBar/)
      end

      it "correctly load module" do 
        TEST_MODULES.each do |mod|
          Automatic::Pipeline.load_plugin mod.to_s
          Automatic::Plugin.const_get(mod).class.should == Class
        end
      end
    end

    describe "#run" do
      it "run a recipe with FilterIgnore module" do
        plugin = mock("plugin")
        plugin.should_receive(:module).and_return("FilterIgnore")
        plugin.should_receive(:config)
        recipe = mock("recipe")
        recipe.should_receive(:each_plugin).and_yield(plugin)
        Automatic::Pipeline.run(recipe).should == []
      end
    end
  end

  describe "in user dir" do 
    before do 
      Automatic.root_dir = File.expand_path(File.join(File.dirname(__FILE__), "../../"))
      Automatic.user_dir = File.expand_path(File.join(File.dirname(__FILE__), "../user_dir/"))
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
