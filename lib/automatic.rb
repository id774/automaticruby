# -*- coding: utf-8 -*-
# Name::        Automatic::Ruby
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 18, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# The framework module: the two directories everything else resolves paths
# against, and the one method that runs a Recipe. See doc/BASIC_DESIGN.md
# section 4.3.

module Automatic
  require 'automatic/environment'
  require 'automatic/log'
  require 'automatic/recipe'
  require 'automatic/pipeline'
  require 'automatic/http'
  require 'automatic/feed_parser'
  require 'automatic/feed_maker'
  require 'automatic/version'

  # The user directory, relative to the home directory.
  USER_DIR = '/.automatic'

  # Base class for every failure the framework raises itself, so that a caller
  # can rescue these without rescuing everything.
  class Error < StandardError; end

  # Pipeline.run was given no Recipe.
  class NoRecipeError < Error; end

  # A Recipe named a module for which no plugin file could be found.
  class NoPluginError < Error; end

  # A Recipe parsed, but is not a document this framework can run.
  class InvalidRecipeError < Error; end

  class << self
    attr_accessor :root_dir

    # Require a gem that only one plugin, or one optional path, needs, and turn
    # its absence into a message naming the gem, what wanted it and how to get
    # it. Nothing here resolves, installs or tracks a dependency: the `require`
    # is the plugin's own, made where the plugin makes it, and this only
    # replaces `cannot load such file -- dalli` with a sentence an operator can
    # act on. See doc/POLICY.md section 9.1 and doc/PLUGINS.md section 3.8.
    #
    #   Automatic.require_optional('sanitize', needed_by: 'FilterSanitize')
    #
    # `gem_name` is given where it differs from the path required, as
    # `active_record` does from the `activerecord` gem.
    def require_optional(feature, needed_by:, gem_name: feature)
      require feature
    rescue LoadError => e
      raise LoadError,
            "The `#{gem_name}` gem is not installed. It is needed by #{needed_by}. " \
            "Install it with `gem install #{gem_name}`, or in a source checkout add " \
            'its group to the bundle; see the optional plugin dependencies in ' \
            "doc/DEPLOYMENT.md. (#{e.message})"
    end

    # Run one Recipe. root_dir is the installation root; user_dir is honoured
    # only under AUTOMATIC_RUBY_ENV=test, which is how the specs point the
    # plugin loader at a fixture directory.
    def run(args = {})
      self.root_dir = args[:root_dir]
      self.user_dir = args[:user_dir]
      Automatic::Pipeline.run(args[:recipe])
    end

    def plugins_dir
      File.join(@root_dir.to_s, 'plugins')
    end

    def config_dir
      File.join(@root_dir.to_s, 'config')
    end

    # Defaults to ~/.automatic when nothing has set it, so that a caller which
    # never went through .run still resolves the user directory.
    def user_dir
      @user_dir ||= default_user_dir
    end

    def user_dir=(dir)
      @user_dir =
        if ENV['AUTOMATIC_RUBY_ENV'] == 'test' && !dir.nil?
          dir
        else
          default_user_dir
        end
    end

    def user_plugins_dir
      File.join(user_dir.to_s, 'plugins')
    end

    # Where a Recipe named by a bare filename is looked for.
    def user_config_dir
      File.join(user_dir.to_s, 'config')
    end

    private

    def default_user_dir
      File.expand_path('~') + USER_DIR
    end
  end
end
