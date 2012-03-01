#!/usr/bin/env ruby
# Name::      Automatic::Ruby
# Author::    774 <http://id774.net>
# Version::   12.02.1-devel
# Created::   Feb 18, 2012
# Updated::   Feb 24, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic
  require 'automatic/environment'
  require 'automatic/recipe'
  require 'automatic/pipeline'
  require 'automatic/log'
  require 'automatic/feed_parser'

  VERSION = "12.02.1-devel"
  
  def self.root_dir
    @root_dir
  end
  
  def self.plugins_dir
    @root_dir + "/plugins/"
  end

  def self.config_dir
    @root_dir + "/config/"
  end

  def self.run(root_dir)
    @root_dir = root_dir
    recipe_path = ""
    require 'optparse'
    parser = OptionParser.new do |parser|
      parser.banner = "Usage: autorb [options] arg"
      parser.version = VERSION
      parser.separator "options:"
      parser.on('-c', '--config FILE', String,
                "recipe YAML file"){|c| recipe_path = c}
      parser.on('-h', '--help', "show this message") do
        puts parser
        exit
      end
    end

    begin
      parser.parse!
      print "Loading #{recipe_path}\n" unless recipe_path == ""
    rescue OptionParser::ParseError => err
      $stderr.puts err.message
      $stderr.puts parser.help
      exit 1
    end

    # recipe treat as an object.
    recipe = Automatic::Recipe.new(recipe_path)
    Automatic::Pipeline.run(recipe)
  end
end
