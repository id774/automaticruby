# -*- coding: utf-8 -*-
# Name::      Automatic::Pipeline
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Mar 10, 2012
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'active_support/core_ext'

module Automatic
  module Plugin end
  class NoPluginError < StandardError; end
  class NoRecipeError < StandardError; end

  module Pipeline
    def self.load_plugin(module_name)
      Dir[Automatic.user_plugins_dir + "/*",
          Automatic.plugins_dir + "/*"].each {|dir|
        subdir = File.basename dir
        if /#{subdir}_(.*)$/ =~ module_name.underscore
          path = dir + "/#{$1}.rb"
          return Automatic::Plugin.autoload module_name.to_sym,
            path.to_s if File.exists? path
        end
      }
      raise NoPluginError, "unknown plugin named #{module_name}"
    end

    def self.run(recipe)
      raise NoRecipeError if recipe.nil?
      pipeline = []
      recipe.each_plugin {|plugin|
        mod = plugin.module
        load_plugin(mod)
        klass = Automatic::Plugin.const_get(mod)
        pipeline = klass.new(plugin.config, pipeline).run
      }
    end
  end
end
