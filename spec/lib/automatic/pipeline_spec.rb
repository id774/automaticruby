# -*- coding: utf-8 -*-
# Name::        Automatic::Pipeline
# Author:       ainame
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar 10, 2012
# Updated::     Sep  6, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

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
        plugin = double("plugin")
        plugin.should_receive(:module).and_return("FilterIgnore")
        plugin.should_receive(:config)
        recipe = double("recipe")
        recipe.should_receive(:each_plugin).and_yield(plugin)
        Automatic::Pipeline.run(recipe).should == []
      end

      # Every module a Recipe names is discovered before any plugin runs, so
      # that an unknown module later on is refused before an earlier plugin's
      # side effect, not after it; doc/PLUGINS.md documents unknown plugin as
      # refused before any plugin runs, wherever in the Recipe it is.
      it "refuses an unknown module before running a plugin that precedes it" do
        good = double("plugin", :module => "FilterIgnore")
        bad  = double("plugin", :module => "NoSuchPluginAtAll")
        recipe = double("recipe")
        recipe.should_receive(:each_plugin).and_yield(good).and_yield(bad)

        expect(good).not_to receive(:config)

        lambda {
          Automatic::Pipeline.run(recipe)
        }.should raise_exception(Automatic::NoPluginError,
          /unknown plugin named NoSuchPluginAtAll/)
      end

      it "refuses an unknown module at the front before a plugin behind it runs" do
        bad  = double("plugin", :module => "NoSuchPluginAtAll")
        good = double("plugin", :module => "FilterIgnore")
        recipe = double("recipe")
        recipe.should_receive(:each_plugin).and_yield(bad).and_yield(good)

        expect(good).not_to receive(:config)

        lambda {
          Automatic::Pipeline.run(recipe)
        }.should raise_exception(Automatic::NoPluginError,
          /unknown plugin named NoSuchPluginAtAll/)
      end

      it "runs every plugin once all named modules are discoverable" do
        first  = double("plugin", :module => "FilterIgnore")
        second = double("plugin", :module => "FilterOne")
        first.should_receive(:config)
        second.should_receive(:config)
        recipe = double("recipe")
        recipe.should_receive(:each_plugin).and_yield(first).and_yield(second)

        Automatic::Pipeline.run(recipe)
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

      it "loads and runs the documented user filter" do
        pipeline = AutomaticSpec.generate_pipeline do
          feed { item "https://example.com/a", "Title" }
        end
        Automatic::Pipeline.load_plugin "FilterTitlePrefix"
        plugin = Automatic::Plugin::FilterTitlePrefix.new(
          { "prefix" => "[News] " }, pipeline
        )

        expect(plugin.run).to equal(pipeline)
        expect(pipeline.first.items.first.title).to eq "[News] Title"
      end
    end

    # FilterLoadMarker (spec/user_dir/plugins/filter/load_marker.rb) has no
    # behaviour of its own; it exists only to be discoverable, so that its
    # presence in $LOADED_FEATURES tells these two examples whether its file
    # was actually read, as distinct from merely registered for autoload.
    # Referencing Automatic::Plugin::FilterLoadMarker directly would load it
    # and defeat that, so neither example does.
    describe "#run and discovery preflight" do
      let(:fixture_path) {
        File.join(APP_ROOT, "spec", "user_dir", "plugins", "filter", "load_marker.rb")
      }

      it "does not load a discoverable plugin's source during preflight, even when an unknown module follows it" do
        expect($LOADED_FEATURES).not_to include(fixture_path)

        good = double("plugin", :module => "FilterLoadMarker")
        bad  = double("plugin", :module => "NoSuchPluginAtAll")
        recipe = double("recipe")
        recipe.should_receive(:each_plugin).and_yield(good).and_yield(bad)

        lambda {
          Automatic::Pipeline.run(recipe)
        }.should raise_exception(Automatic::NoPluginError,
          /unknown plugin named NoSuchPluginAtAll/)

        expect($LOADED_FEATURES).not_to include(fixture_path)
      end

      it "loads a discoverable plugin's source only once execution reaches it" do
        plugin = double("plugin", :module => "FilterLoadMarker")
        plugin.should_receive(:config)
        recipe = double("recipe")
        recipe.should_receive(:each_plugin).and_yield(plugin)

        Automatic::Pipeline.run(recipe)

        expect($LOADED_FEATURES).to include(fixture_path)
      end
    end
  end
end
