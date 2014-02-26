# -*- coding: utf-8 -*-
# Name::      Automatic::Recipe
# Author::    ainame
#             774 <http://id774.net>
# Created::   Feb 18, 2012
# Updated::   Jun 14, 2012
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'hashie'
require 'yaml'

module Automatic
  class Recipe
    attr_reader :procedure

    def initialize(path = "")
      load_recipe(path)
    end

    def load_recipe(path)
      dir = File.join((File.expand_path('~/.automatic/config/')), path)
      path = dir if File.exist?(dir)
      @procedure = Hashie::Mash.new(YAML.load(File.read(path)))
      log_level = @procedure.global && @procedure.global.log && @procedure.global.log.level
      Automatic::Log.level(log_level)
      Automatic::Log.puts("info", "Loading Recipe: #{path}")
      @procedure
    end

    def each_plugin
      @procedure.plugins.each {|plugin|
        yield plugin
      }
    end
  end
end
