#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Core
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 22, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

class Automatic
  def self.core(recipe)
    basedir = File.dirname(__FILE__)
    $:.unshift File.join(basedir, '..', 'plugins', 'subscription')
    $:.unshift File.join(basedir, '..', 'plugins', 'filter')
    $:.unshift File.join(basedir, '..', 'plugins', 'store')
    $:.unshift File.join(basedir, '..', 'plugins', 'publish')

    Dir.glob(basedir + '/../plugins/**/*.rb').each {|r|
      require(File.basename(r, '.rb'))
    }

    require 'yaml'
    if recipe == ""
      recipe = basedir + '/../config/default.yml'
    end

    File.open(recipe) {|io|
      YAML.load_documents(io) {|yaml|
        @pipeline = []
        yaml['plugins'].each {|plugin|
          loader = eval(plugin['module']).new(plugin['config'], @pipeline)
          @pipeline = loader.run
        }
      }
    }
  end
end
