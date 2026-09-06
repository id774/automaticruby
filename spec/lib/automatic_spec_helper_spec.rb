# -*- coding: utf-8 -*-
# Name::        AutomaticSpec
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Sep  6, 2026
# Updated::     Sep  6, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# AutomaticSpec.plugin_available? itself, defined in spec_helper.rb. Every
# plugin spec that guards itself with it relies on it skipping only a plugin's
# own missing optional gem, and failing on anything else the plugin's load
# raises; see doc/POLICY.md Invariant 7.

require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

describe AutomaticSpec do
  describe "#plugin_available?" do
    # Puts one throwaway file on the load path under a name unique to this
    # example, so a plugin body can be written inline without touching the
    # real plugins/ tree or any external gem.
    def with_plugin_file(contents)
      Dir.mktmpdir("automatic-ruby-plugin-available-spec") do |dir|
        feature = "automatic_plugin_available_spec_plugin"
        full_path = File.join(dir, "#{feature}.rb")
        File.write(full_path, contents)
        $LOAD_PATH.unshift dir
        begin
          yield feature
        ensure
          $LOAD_PATH.delete(dir)
          $LOADED_FEATURES.delete(full_path)
        end
      end
    end

    it "returns true when the plugin loads cleanly" do
      with_plugin_file('') do |feature|
        expect(AutomaticSpec.plugin_available?(feature)).to be true
      end
    end

    it "returns false and records the skip when the plugin's own optional gem is missing" do
      with_plugin_file(<<~RUBY) do |feature|
        Automatic.require_optional('automatic_no_such_gem', needed_by: 'a spec')
      RUBY
        before = AutomaticSpec.skipped_plugins.length

        expect(AutomaticSpec.plugin_available?(feature)).to be false
        expect(AutomaticSpec.skipped_plugins.length).to eq before + 1
        expect(AutomaticSpec.skipped_plugins.last.first).to eq feature
      end
    end

    # A plugin whose own load fails for an unrelated reason -- a typo, a
    # broken installation, a dependency missing something other than the gem
    # the plugin asked require_optional for -- is not an absent optional gem,
    # and must not be swallowed into a skip: doing so would turn a genuine
    # breakage into a silently-passing suite.
    it "propagates a LoadError raised from inside the plugin's own load, unconverted" do
      with_plugin_file("require 'automatic_inner_missing_feature'\n") do |feature|
        before = AutomaticSpec.skipped_plugins.length

        expect {
          AutomaticSpec.plugin_available?(feature)
        }.to raise_error(LoadError, /automatic_inner_missing_feature/)
        expect(AutomaticSpec.skipped_plugins.length).to eq before
      end
    end
  end
end
