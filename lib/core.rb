#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Core
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 22, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

class Automatic
  require 'pathname'
  require 'yaml'

  def self.core(recipe)
    basedir = Pathname.new(__FILE__).parent.parent
    recipe = basedir + 'config/default.yml' if recipe.empty?

    Pathname.glob(basedir + 'plugins/*/*.rb').each do |path|
      klass_name =
        path.parent.basename.to_s.split('_').map(&:capitalize).join +
        path.basename('.rb').to_s.split('_').map(&:capitalize).join

      autoload klass_name.to_sym, path.to_s
    end

    @pipeline = []
    YAML.load(File.read(recipe))['plugins'].each do |plugin|
      klass = eval(plugin['module'])
      @pipeline = klass.new(plugin['config'], @pipeline).run
    end
  end
end
