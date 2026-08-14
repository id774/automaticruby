# -*- coding: utf-8 -*-
# Name::      Automatic::Ruby
# Author::    774 <http://id774.net>
# Created::   Feb 18, 2012
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.
#
# The framework module: the two directories everything else resolves paths
# against, and the one method that runs a Recipe. See doc/BASIC_DESIGN.md
# section 4.3.

module Automatic
  require 'automatic/environment'
  require 'automatic/log'
  require 'automatic/recipe'
  require 'automatic/pipeline'
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
