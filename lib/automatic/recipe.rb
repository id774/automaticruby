# -*- coding: utf-8 -*-
# Name::        Automatic::Recipe
# Author:       ainame
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 18, 2012
# Updated::     Sep  6, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# Turns a Recipe file into something the pipeline can iterate. The format is
# specified in doc/PLUGINS.md section 2.
#
# Each plugin entry's documented shape -- a mapping naming a module, with an
# optional config mapping -- is validated here, at load time, rather than
# left to surface as whatever internal exception a malformed entry happens to
# raise once the pipeline reaches it.

require 'date'
require 'hashie'
require 'yaml'

module Automatic
  class Recipe
    # A Recipe is trusted local configuration, but it is still loaded safely:
    # the document may name none of its own Ruby classes to instantiate. That
    # costs nothing, since no Recipe needs it. It is a second line of defence
    # and not the trust boundary; see doc/REQUIREMENTS.md section 17.
    PERMITTED_CLASSES = [Date, Time, Symbol].freeze

    attr_reader :procedure

    def initialize(path = '')
      load_recipe(path)
    end

    def load_recipe(path)
      resolved = resolve_path(path)
      document = parse(resolved)

      unless document.is_a?(Hash)
        raise InvalidRecipeError,
              "recipe #{resolved} is not a mapping"
      end

      @procedure = Hashie::Mash.new(document)

      unless @procedure.plugins.is_a?(Array)
        raise InvalidRecipeError,
              "recipe #{resolved} has no plugins sequence"
      end

      validate_plugins(resolved)

      Automatic::Log.level(@procedure.global&.log&.level)
      Automatic::Log.puts('info', "Loading Recipe: #{resolved}")
      @procedure
    end

    def each_plugin
      return enum_for(:each_plugin) unless block_given?

      @procedure.plugins.each { |plugin| yield plugin }
    end

    private

    # A bare filename is looked for in the user's config directory first;
    # anything not found there is used as a path exactly as given.
    def resolve_path(path)
      in_user_dir = File.join(Automatic.user_config_dir, path.to_s)
      File.exist?(in_user_dir) ? in_user_dir : path.to_s
    end

    def parse(path)
      YAML.safe_load(
        File.read(path),
        permitted_classes: PERMITTED_CLASSES,
        aliases: true
      )
    end

    # Only the shape doc/PLUGINS.md documents is checked here: a mapping
    # naming a module, with an optional config mapping. What a plugin does
    # with its own config is that plugin's concern, not this one's.
    def validate_plugins(resolved)
      @procedure.plugins.each_with_index do |plugin, index|
        validate_plugin_entry(resolved, plugin, index)
      end
    end

    def validate_plugin_entry(resolved, plugin, index)
      unless plugin.is_a?(Hash)
        raise InvalidRecipeError,
              "recipe #{resolved} plugins[#{index}] is not a mapping"
      end

      validate_module_name(resolved, plugin, index)
      validate_plugin_config(resolved, plugin, index)
    end

    def validate_module_name(resolved, plugin, index)
      name = plugin['module']

      return if name.is_a?(String) && !name.strip.empty?

      raise InvalidRecipeError,
            "recipe #{resolved} plugins[#{index}] has no module name"
    end

    def validate_plugin_config(resolved, plugin, index)
      config = plugin['config']

      return if config.nil? || config.is_a?(Hash)

      raise InvalidRecipeError,
            "recipe #{resolved} plugins[#{index}] has a config that is not a mapping"
    end
  end
end
