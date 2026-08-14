# -*- coding: utf-8 -*-
# Name::        Automatic::Pipeline
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 22, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# The core: resolve a plugin's class name to a file, then run the Recipe's
# plugins in order, each receiving the previous one's output. See
# doc/BASIC_DESIGN.md section 4.6 and doc/PLUGINS.md section 3.

require 'active_support/core_ext/string/inflections'

module Automatic
  # The namespace every plugin class lives in. Plugin files are registered
  # here with autoload, so a file is read when its constant is first used.
  module Plugin; end

  module Pipeline
    class << self
      # Resolve a module name such as SubscriptionFeed to
      # <search root>/subscription/feed.rb and register it for autoloading.
      #
      # The user directory is searched before the installation, so a plugin in
      # ~/.automatic/plugins shadows a shipped plugin of the same name.
      def load_plugin(module_name)
        underscored = module_name.underscore

        search_roots.each do |dir|
          category = File.basename(dir)
          next unless /\A#{Regexp.escape(category)}_(.*)\z/ =~ underscored

          path = File.join(dir, "#{Regexp.last_match(1)}.rb")
          next unless File.exist?(path)

          return Automatic::Plugin.autoload(module_name.to_sym, path)
        end

        raise NoPluginError, "unknown plugin named #{module_name}"
      end

      # Run a Recipe: each plugin's return value is the next plugin's input.
      #
      # Nothing here rescues a plugin's exception. A Recipe is a sequence in
      # which each step consumes the previous one's output, so continuing past
      # a failed step would run the rest on a value their author never
      # intended. See doc/REQUIREMENTS.md section 12.
      def run(recipe)
        raise NoRecipeError, 'no recipe given' if recipe.nil?

        pipeline = []
        recipe.each_plugin do |plugin|
          mod = plugin.module
          load_plugin(mod)
          klass = Automatic::Plugin.const_get(mod)
          pipeline = klass.new(plugin.config, pipeline).run
        end
        pipeline
      end

      private

      def search_roots
        Dir[File.join(Automatic.user_plugins_dir, '*'),
            File.join(Automatic.plugins_dir, '*')].select { |path|
          File.directory?(path)
        }
      end
    end
  end
end
