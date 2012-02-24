#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Ruby
# Author::    774 <http://id774.net>
# Version::   12.02-devel
# Created::   Feb 18, 2012
# Updated::   Feb 24, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

lib = File.expand_path(File.dirname(__FILE__) + '/lib')
$:.unshift(lib) if File.directory?(lib) && !$:.include?(lib)

Dir[lib + '/*.rb'].each {|r|
  require File.basename(r, '.rb')
}

if __FILE__ == $0
  recipe = ""
  require 'optparse'
  parser = OptionParser.new do |parser|
    parser.version = "12.02-devel"
    parser.banner = "#{File.basename($0,".*")}
    Usage: #{File.basename($0,".*")} [options] arg"
    parser.separator "options:"
    parser.on('-c', '--config FILE', String,
              "recipe YAML file"){|c| recipe = c}
    parser.on('-h', '--help', "show this message"){
      puts parser
      exit
    }
  end

  begin
    parser.parse!
    print "Loading #{recipe}\n" unless recipe.empty?
  rescue OptionParser::ParseError => err
    $stderr.puts err.message
    $stderr.puts parser.help
    exit 1
  end
  Core.pipeline(recipe)
end
