# -*- coding: utf-8 -*-
# Name::        Automatic::CLI
# Author:       id774 (More info: https://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 14, 2026
# Updated::     Sep  9, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.join(File.dirname(__FILE__), '../../spec_helper'))

require 'automatic/cli'
require 'fileutils'
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

  describe "the feedparser subcommand" do
    it "parses a valid HTTP or HTTPS URL" do
      allow(Automatic::FeedParser).to receive(:get_url).and_return("parsed")

      expect(run("feedparser", "https://example.com/feed")).to eq Automatic::CLI::EXIT_SUCCESS
      expect(Automatic::FeedParser).to have_received(:get_url).with("https://example.com/feed")
      expect(out.string).to match(/parsed/)
      expect(err.string).to be_empty
    end

    it "rejects a URL whose scheme is not HTTP or HTTPS" do
      expect(Automatic::FeedParser).not_to receive(:get_url)

      expect(run("feedparser", "file:///etc/passwd")).to eq Automatic::CLI::EXIT_FAILURE
      expect(out.string).to be_empty
      expect(err.string).to match(/automatic: not an HTTP or HTTPS URL:/)
    end

    it "rejects an HTTP or HTTPS URL with no host" do
      expect(Automatic::FeedParser).not_to receive(:get_url)

      expect(run("feedparser", "https:/feed")).to eq Automatic::CLI::EXIT_FAILURE
      expect(out.string).to be_empty
      expect(err.string).to match(/automatic: HTTP or HTTPS URL has no host:/)
    end

    it "rejects a URL that fails to parse as a URI syntax error" do
      expect(Automatic::FeedParser).not_to receive(:get_url)

      expect(run("feedparser", "http://[")).to eq Automatic::CLI::EXIT_FAILURE
      expect(out.string).to be_empty
      expect(err.string).to match(/\Aautomatic: /)
    end

    it "propagates an unexpected internal ArgumentError from FeedParser, unconverted" do
      allow(Automatic::FeedParser).to receive(:get_url)
        .and_raise(ArgumentError, 'internal feed parser defect')

      expect {
        run("feedparser", "https://example.com/feed")
      }.to raise_error(ArgumentError, /internal feed parser defect/)
    end
  end

  describe "the inspect subcommand" do
    it "fails cleanly when no feed is discovered" do
      stub_const("Feedbag", Class.new)
      allow(Automatic).to receive(:require_optional)
      allow(Feedbag).to receive(:find).and_return([])

      expect(run("inspect", "https://example.com/")).to eq Automatic::CLI::EXIT_FAILURE
      expect(err.string).to match(%r{no feed found at https://example\.com/})
      expect(out.string).to be_empty
    end

    it "parses the first feed when several are discovered" do
      stub_const("Feedbag", Class.new)
      allow(Automatic).to receive(:require_optional)
      allow(Feedbag).to receive(:find)
        .and_return(["https://example.com/first", "https://example.com/second"])
      allow(Automatic::FeedParser).to receive(:get_url).and_return("parsed")

      expect(run("inspect", "https://example.com/")).to eq Automatic::CLI::EXIT_SUCCESS
      expect(Automatic::FeedParser).to have_received(:get_url).with("https://example.com/first")
    end
  end

  describe "the autodiscovery subcommand" do
    # These stub Automatic.require_optional itself, rather than an actually
    # missing or present feedbag, so the two cases below are exercised
    # deterministically regardless of whether feedbag happens to be installed
    # in the environment running the suite. What require_optional itself
    # classifies as a direct missing dependency is covered in automatic_spec.rb.
    it "reports a dedicated optional dependency error as a one-line diagnostic and fails" do
      allow(Automatic).to receive(:require_optional)
        .and_raise(Automatic::OptionalDependencyError,
                    "The `feedbag` gem is not installed. It is needed by the " \
                    'autodiscovery subcommand. Install it with `gem install feedbag`.')

      expect(run("autodiscovery", "https://example.com/")).to eq Automatic::CLI::EXIT_FAILURE
      expect(err.string).to match(/`feedbag` gem is not installed/)
    end

    it "propagates a LoadError raised from inside a feature's own load, unconverted" do
      allow(Automatic).to receive(:require_optional)
        .and_raise(LoadError, "cannot load such file -- automatic_inner_missing_feature")

      expect {
        run("autodiscovery", "https://example.com/")
      }.to raise_error(LoadError, /automatic_inner_missing_feature/)
    end
  end

  describe "the scaffold subcommand" do
    around do |example|
      Dir.mktmpdir("automatic-ruby-scaffold-spec") do |dir|
        @scaffold_user_dir = dir
        Automatic.user_dir = dir
        example.run
      end
      Automatic.user_dir = nil
    end

    def run_scaffold
      run("scaffold", root_dir: APP_ROOT)
    end

    it "creates the missing bundled siteinfo when the assets directory already exists" do
      FileUtils.mkdir_p(File.join(@scaffold_user_dir, "assets"))

      expect(run_scaffold).to eq Automatic::CLI::EXIT_SUCCESS

      siteinfo = File.join(@scaffold_user_dir, "assets", "siteinfo")
      expect(File.directory?(siteinfo)).to be true
      expect(Dir.children(siteinfo)).not_to be_empty
    end

    it "creates the missing bundled example configuration when the config directory already exists" do
      FileUtils.mkdir_p(Automatic.user_config_dir)

      expect(run_scaffold).to eq Automatic::CLI::EXIT_SUCCESS

      example_config = File.join(Automatic.user_config_dir, "example")
      expect(File.directory?(example_config)).to be true
      expect(Dir.children(example_config)).not_to be_empty
    end

    it "does not overwrite an existing siteinfo directory" do
      siteinfo = File.join(@scaffold_user_dir, "assets", "siteinfo")
      FileUtils.mkdir_p(siteinfo)
      File.write(File.join(siteinfo, "marker.txt"), "existing user data")

      expect(run_scaffold).to eq Automatic::CLI::EXIT_SUCCESS

      expect(File.read(File.join(siteinfo, "marker.txt"))).to eq "existing user data"
    end

    it "does not overwrite an existing example configuration directory" do
      example_config = File.join(Automatic.user_config_dir, "example")
      FileUtils.mkdir_p(example_config)
      File.write(File.join(example_config, "marker.txt"), "existing user data")

      expect(run_scaffold).to eq Automatic::CLI::EXIT_SUCCESS

      expect(File.read(File.join(example_config, "marker.txt"))).to eq "existing user data"
    end

    it "leaves existing user data untouched when run repeatedly" do
      run_scaffold

      siteinfo = File.join(@scaffold_user_dir, "assets", "siteinfo")
      example_config = File.join(Automatic.user_config_dir, "example")
      File.write(File.join(siteinfo, "marker.txt"), "kept across reruns")
      File.write(File.join(example_config, "marker.txt"), "kept across reruns")

      expect(run_scaffold).to eq Automatic::CLI::EXIT_SUCCESS

      expect(File.read(File.join(siteinfo, "marker.txt"))).to eq "kept across reruns"
      expect(File.read(File.join(example_config, "marker.txt"))).to eq "kept across reruns"
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

    # A plugin's optional gem is installed by the operator who uses the plugin
    # (doc/POLICY.md section 9.1), so not having one is an ordinary situation
    # with an answer. It is reported as a message naming the gem and the
    # plugin, not as a backtrace.
    it "reports a plugin's missing optional gem as a message" do
      # The user plugin directory of the redirected HOME, named here rather
      # than asked of Automatic, so that this writes into the spec's temporary
      # home whatever another example has left the user directory set to.
      plugins = File.join(File.expand_path("~"), ".automatic", "plugins", "filter")
      FileUtils.mkdir_p(plugins)
      File.write(File.join(plugins, "needs_gem.rb"), <<~RUBY)
        module Automatic::Plugin
          class FilterNeedsGem
            Automatic.require_optional('automatic_no_such_gem',
                                       needed_by: 'FilterNeedsGem')
          end
        end
      RUBY

      Dir.mktmpdir do |dir|
        path = File.join(dir, "recipe.yml")
        File.write(path, "plugins:\n  - module: FilterNeedsGem\n")
        expect(run("-c", path)).to eq Automatic::CLI::EXIT_FAILURE
        expect(err.string).to match(/`automatic_no_such_gem` gem is not installed/)
        expect(err.string).to match(/FilterNeedsGem/)
        expect(err.string).to match(/gem install automatic_no_such_gem/)
      end
    end

    # A LoadError raised from inside a plugin's own load -- for a file other
    # than the optional gem it asked require_optional for -- is a broken
    # plugin or a broken dependency, not an absent optional gem, and must not
    # be hidden behind the same one-line diagnostic; see doc/PLUGINS.md
    # section 2.7.
    it "propagates a LoadError raised from inside a plugin's own load, unconverted" do
      allow(Automatic).to receive(:run)
        .and_raise(LoadError, "cannot load such file -- automatic_inner_missing_feature")

      Dir.mktmpdir do |dir|
        path = File.join(dir, "recipe.yml")
        File.write(path, "plugins:\n  - module: FilterOne\n")
        expect { run("-c", path) }.to raise_error(LoadError, /automatic_inner_missing_feature/)
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
