# -*- coding: utf-8 -*-
# Name::        Automatic::Spec
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar  9, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# The suite reaches no network and needs no credential. That is a rule, not a
# coincidence; see doc/POLICY.md section 5.

APP_ROOT = File.expand_path('..', __dir__)

$LOAD_PATH.unshift File.join(APP_ROOT, 'lib')
$LOAD_PATH.unshift File.join(APP_ROOT, 'plugins')

ENV['AUTOMATIC_RUBY_ENV'] ||= 'test'

if ENV['COVERAGE'] == 'on'
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
    add_filter 'test'
    add_filter 'vendor'
  end
end

require 'active_support/core_ext/object/blank'
require 'rspec/collection_matchers'
require 'rspec/its'
require 'rss'
require 'fileutils'
require 'tmpdir'

require 'automatic'

Automatic::Log.level('none')

# Supporting files with custom matchers and macros, if any.
Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |file| require file }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    # The plugin specs were written against RSpec 2 and use should_receive.
    # Keeping both syntaxes is what lets them run unchanged; see
    # doc/POLICY.md section 2.2 on not rewriting what is not being changed.
    mocks.syntax = %i[should expect]
    mocks.verify_partial_doubles = false
  end

  config.expect_with :rspec do |expectations|
    expectations.syntax = %i[should expect]
  end

  # Examples tagged :network reach real hosts. They are excluded from the
  # default suite and from CI, because the suite must need neither a network
  # nor a credential (doc/POLICY.md Invariant 6). Several of them point at
  # hosts that no longer serve what they expect, which is a further reason not
  # to make them a gate. Run them deliberately with:
  #
  #   AUTOMATIC_NETWORK_SPECS=1 bundle exec rake spec
  #
  config.filter_run_excluding :network unless ENV['AUTOMATIC_NETWORK_SPECS'] == '1'
end

# Builds pipeline values for a plugin spec:
#
#   AutomaticSpec.generate_pipeline do
#     feed { item 'https://example.com/', 'title', 'description' }
#   end
#
module AutomaticSpec
  REAL_HOME = ENV['HOME']
  TEST_HOME = Dir.mktmpdir('automatic-ruby-spec-home')
  TEST_DB_DIR = File.join(TEST_HOME, '.automatic', 'db')
  FileUtils.mkdir_p(TEST_DB_DIR)
  ENV['HOME'] = TEST_HOME

  at_exit do
    ENV['HOME'] = REAL_HOME
    FileUtils.remove_entry(TEST_HOME) if File.directory?(TEST_HOME)
  end

  # Gems the Gemfile declares in its optional :plugins group. They are not
  # runtime dependencies of the framework, `bundle install` does not install
  # them, and the default suite therefore does not verify the plugins that need
  # them. Which plugin needs which is in doc/PLUGINS.md section 6.
  #
  # This is a declared list rather than something inferred from a load failure:
  # what the default suite does not cover is decided here, in one place, and a
  # spec that names a gem absent from this list is a mistake and says so.
  OPTIONAL_PLUGIN_GEMS = %w[nkf sanitize].freeze

  class << self
    # Load a plugin, or report that its dependency is absent.
    #
    # A plugin whose gem is not installed -- because the service it talks to no
    # longer exists, and no currently published gem speaks to it -- is never
    # stubbed into passing (doc/POLICY.md Invariant 7). Its spec is skipped
    # instead, and the reason is printed, which is the honest signal.
    def plugin_available?(path)
      require path
      true
    rescue LoadError => e
      skipped_plugins << [path, e.message]
      warn "[automatic] skipping #{path} spec: #{e.message}"
      false
    end

    # Whether an optional plugin gem is in this bundle. A spec whose plugin
    # needs one guards its whole file with this, because the plugin's own
    # `require` runs when the file loads.
    #
    #   if AutomaticSpec.optional_dependency?('sanitize')
    #     require 'filter/sanitize'
    #     describe ... do ... end
    #   end
    #
    # Installing the group is what runs these:
    #
    #   BUNDLE_WITH=plugins bundle install
    def optional_dependency?(gem_name)
      unless OPTIONAL_PLUGIN_GEMS.include?(gem_name)
        raise ArgumentError,
              "#{gem_name} is not one of the optional plugin gems the Gemfile declares"
      end

      return true if Gem::Specification.find_all_by_name(gem_name).any?

      skipped_optional << gem_name
      warn "[automatic] not verified by this run: the optional plugin gem " \
           "#{gem_name} is not installed (BUNDLE_WITH=plugins bundle install)"
      false
    end

    def skipped_plugins
      @skipped_plugins ||= []
    end

    def skipped_optional
      @skipped_optional ||= []
    end

    def generate_pipeline(&block)
      generator = StubPipelineGenerator.new
      generator.instance_eval(&block)
      generator.pipeline
    end

    def root_dir
      APP_ROOT
    end

    def db_dir
      TEST_DB_DIR
    end
  end

  class StubPipelineGenerator
    attr_reader :pipeline

    def initialize
      @pipeline = []
    end

    def feed(&block)
      generator = StubFeedGenerator.new
      generator.instance_eval(&block)
      @pipeline << generator.feed
    end
  end

  class StubFeedGenerator
    def initialize
      @channel = RSS::Rss::Channel.new
    end

    def feed
      rss = RSS::Rss.new([])
      rss.instance_variable_set(:@channel, @channel)
      rss
    end

    def item(url, title = '', description = '', date = '', author = '',
             source = '', enclosure = '')
      item = RSS::Rss::Channel::Item.new
      item.link = url
      item.title = title unless title.blank?
      item.instance_variable_set(:@description, description)
      item.pubDate = date unless date.blank?
      item.author = author unless author.blank?
      item.source = source unless source.blank?
      item.enclosure = enclosure unless enclosure.blank?
      @channel.items << item
    end
  end
end
