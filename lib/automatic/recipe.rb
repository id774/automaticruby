# -*- coding: utf-8 -*-
# Name::      Automatic::Recipe
# Author::    ainame
#             774 <http://id774.net>
# Created::   Feb 18, 2012
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.
#
# Turns a Recipe file into something the pipeline can iterate. The format is
# specified in doc/PLUGINS.md section 2.

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
  end
end
