# -*- coding: utf-8 -*-
# Name::      Automatic::Recipe (loading and refusal)
# Author::    774 <http://id774.net>
# Created::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.join(File.dirname(__FILE__), '../../spec_helper'))

require 'automatic'
require 'automatic/recipe'
require 'tmpdir'

describe Automatic::Recipe do
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  def recipe(body)
    path = File.join(@dir, "recipe.yml")
    File.write(path, body)
    Automatic::Recipe.new(path)
  end

  describe "what it refuses" do
    it "refuses a document that is not a mapping" do
      expect { recipe("- one\n- two\n") }.
        to raise_error Automatic::InvalidRecipeError, /not a mapping/
    end

    it "refuses a document with no plugins sequence" do
      expect { recipe("global:\n  log:\n    level: none\n") }.
        to raise_error Automatic::InvalidRecipeError, /no plugins sequence/
    end

    it "refuses a plugins key that is not a sequence" do
      expect { recipe("plugins: nope\n") }.
        to raise_error Automatic::InvalidRecipeError, /no plugins sequence/
    end

    # A Recipe is trusted local configuration, but it is still loaded safely,
    # so that the document itself cannot name a Ruby class to instantiate.
    # See doc/REQUIREMENTS.md section 17 and doc/POLICY.md section 1.11.
    it "refuses a document naming an arbitrary Ruby class" do
      body = "plugins:\n  - module: PublishConsole\n    config: !ruby/object:Struct {}\n"
      expect { recipe(body) }.to raise_error Psych::DisallowedClass
    end
  end

  describe "what it accepts" do
    it "reads the plugins in order" do
      body = <<~YAML
        plugins:
          - module: SubscriptionText
            config:
              titles:
                - one
          - module: FilterOne
          - module: PublishConsole
      YAML
      expect(recipe(body).each_plugin.map { |plugin| plugin.module }).
        to eq %w[SubscriptionText FilterOne PublishConsole]
    end

    it "leaves an entry without config as nil" do
      body = "plugins:\n  - module: FilterClear\n"
      expect(recipe(body).each_plugin.first.config).to be_nil
    end

    # Aliases let a block of settings be shared between plugins, which is a
    # legitimate use and is documented in doc/PLUGINS.md section 2.6.
    it "resolves YAML aliases" do
      body = <<~YAML
        plugins:
          - module: SubscriptionText
            config: &shared
              retry: 3
              interval: 5
          - module: FilterOne
            config:
              <<: *shared
      YAML
      expect(recipe(body).each_plugin.to_a.last.config['retry']).to eq 3
    end

    it "takes the log level from global" do
      recipe("global:\n  log:\n    level: warn\nplugins: []\n")
      expect(Automatic::Log.send(:current_level)).to eq 'warn'
      Automatic::Log.level('none')
    end

    it "falls back to the default level when global is absent" do
      recipe("plugins: []\n")
      expect(Automatic::Log.send(:current_level)).to eq Automatic::Log::DEFAULT_LEVEL
      Automatic::Log.level('none')
    end
  end
end
