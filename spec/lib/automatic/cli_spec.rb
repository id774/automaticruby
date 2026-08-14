# -*- coding: utf-8 -*-
# Name::        Automatic::CLI
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 14, 2026
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.join(File.dirname(__FILE__), '../../spec_helper'))

require 'automatic/cli'
require 'stringio'
require 'tmpdir'

describe Automatic::CLI do
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  def run(*argv, root_dir: APP_ROOT)
    described_class.run(argv, root_dir: root_dir, stdout: out, stderr: err)
  end

  describe "exit statuses" do
    it "prints the version and succeeds" do
      expect(run("--version")).to eq Automatic::CLI::EXIT_SUCCESS
      expect(out.string.strip).to eq Automatic::VERSION
    end

    it "accepts the short version flag" do
      expect(run("-v")).to eq Automatic::CLI::EXIT_SUCCESS
      expect(out.string.strip).to eq Automatic::VERSION
    end

    it "prints help and succeeds" do
      expect(run("--help")).to eq Automatic::CLI::EXIT_SUCCESS
      expect(out.string).to match(/Usage: automatic/)
      expect(out.string).to match(/SubCommands:/)
    end

    it "prints usage and fails when nothing is asked for" do
      expect(run).to eq Automatic::CLI::EXIT_FAILURE
      expect(out.string).to match(/Usage: automatic/)
    end

    it "rejects an unknown option with the usage status" do
      expect(run("--no-such-option")).to eq Automatic::CLI::EXIT_USAGE
      expect(err.string).to match(/invalid option/)
    end

    it "fails on an unknown subcommand" do
      expect(run("frobnicate")).to eq Automatic::CLI::EXIT_FAILURE
      expect(err.string).to match(/no such subcommand: frobnicate/)
    end

    it "fails on a missing recipe without raising" do
      expect(run("-c", "/nonexistent/recipe.yml")).to eq Automatic::CLI::EXIT_FAILURE
      expect(err.string).to match(%r{no such recipe: /nonexistent/recipe\.yml})
    end

    it "fails on a subcommand invoked without its argument" do
      expect(run("opmlparser")).to eq Automatic::CLI::EXIT_FAILURE
      expect(err.string).to match(/Usage: automatic opmlparser/)
    end
  end

  describe "the log subcommand" do
    it "emits a message through the framework's logger" do
      expect(run("log", "error", "hello")).to eq Automatic::CLI::EXIT_SUCCESS
    end
  end

  describe "the opmlparser subcommand" do
    it "prints the feed URLs of an OPML file" do
      path = File.join(APP_ROOT, "test", "fixtures", "sampleOPML.xml")
      expect(run("opmlparser", path)).to eq Automatic::CLI::EXIT_SUCCESS
      expect(out.string).not_to be_empty
    end
  end

  describe "running a recipe" do
    # A recipe of plugins that reach nothing: the framework is exercised
    # end to end without a network, which is what the suite is allowed to do.
    let(:recipe) do
      <<~YAML
        global:
          log:
            level: none

        plugins:
          - module: SubscriptionText
            config:
              feeds:
                - title: hello
                  url: https://example.com/a
          - module: FilterOne
      YAML
    end

    it "runs it and succeeds" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "recipe.yml")
        File.write(path, recipe)
        expect(run("-c", path)).to eq Automatic::CLI::EXIT_SUCCESS
        expect(err.string).to be_empty
      end
    end

    it "fails when the recipe names an unknown plugin" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "recipe.yml")
        File.write(path, "plugins:\n  - module: NoSuchThing\n")
        expect(run("-c", path)).to eq Automatic::CLI::EXIT_FAILURE
        expect(err.string).to match(/unknown plugin named NoSuchThing/)
      end
    end

    it "fails when the recipe has no plugins sequence" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "recipe.yml")
        File.write(path, "global:\n  log:\n    level: none\n")
        expect(run("-c", path)).to eq Automatic::CLI::EXIT_FAILURE
        expect(err.string).to match(/no plugins sequence/)
      end
    end

    it "fails on malformed YAML without raising" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "recipe.yml")
        File.write(path, "plugins:\n  - module: [unclosed\n")
        expect(run("-c", path)).to eq Automatic::CLI::EXIT_FAILURE
        expect(err.string).not_to be_empty
      end
    end
  end
end
