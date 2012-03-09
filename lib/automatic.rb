#!/usr/bin/env ruby
# Name::      Automatic::Ruby
# Author::    774 <http://id774.net>
# Version::   12.03-devel
# Created::   Feb 18, 2012
# Updated::   Mar 10, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic
  require 'automatic/environment'
  require 'automatic/recipe'
  require 'automatic/pipeline'
  require 'automatic/log'
  require 'automatic/feed_parser'

  VERSION = "12.03-devel"
  USER_DIR = "/.automatic"

  class << self
    def run(root_dir, user_dir = nil)
      @root_dir = root_dir
      set_user_dir(user_dir)
      recipe_path = ""
      require 'optparse'
      parser = OptionParser.new { |parser|
        parser.banner = "Usage: automatic [options] arg"
        parser.version = VERSION
        parser.separator "options:"
        parser.on('-c', '--config FILE', String,
                  "recipe YAML file"){|c| recipe_path = c}
        parser.on('-h', '--help', "show this message") { 
          puts parser
          exit
        }
      }

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

    def root_dir
      @root_dir
    end

    def plugins_dir
      File.join(@root_dir, "plugins")
    end

    def config_dir
      File.join(@root_dir, "config")
    end

    def set_user_dir(user_dir)
      if ENV["AUTOMATIC_RUBY_ENV"] == "test" && !(user_dir.nil?)
        @user_dir = user_dir 
      else
        @user_dir = Dir.home + USER_DIR
      end
    end

    def user_dir
      @user_dir
    end

    def user_plugins_dir
      File.join(@user_dir, "plugins")
    end

  end

end
