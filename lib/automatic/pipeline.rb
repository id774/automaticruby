#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Pipeline
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Mar 3, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'active_support/core_ext'

module Automatic
  module Plugin end

  module Pipeline
    def self.load_plugin(module_name)
      Dir[Automatic.plugins_dir+"/*.rb", 
          Automatic.user_plugins_dir+"/*.rb"].each{ |subdir|
        if /^#{subdir}_(.*)$/ =~ module_name.underscore
          path = Automatic.plugins_dir + subdir + "/#{$1}.rb"
          Automatic::Plugin.autoload module_name.to_sym, path.to_s
        end
      }
    end
 
    def self.run(recipe)
      raise "NoRecipeError" if recipe.nil?
      pipeline = []
      recipe.each_plugin { |plugin|
        load_plugin(plugin.module)
        klass = Automatic::Plugin.const_get(plugin.module)
        pipeline = klass.new(plugin.config, pipeline).run
      }
    end
  end
end

