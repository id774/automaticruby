#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class Automatic
  def self.core(recipe)
    basedir = File.dirname(__FILE__)
    $:.unshift File.join(basedir, '..', 'plugins', 'subscription')
    $:.unshift File.join(basedir, '..', 'plugins', 'filter')
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
