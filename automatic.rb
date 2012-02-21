#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
basedir = File.dirname(__FILE__)
$:.unshift File.join(basedir, 'lib')
Dir.glob(basedir + '/lib/*.rb').each {|r|
  require(File.basename(r, '.rb'))
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
    print "Loading #{recipe}\n" unless recipe == ""
  rescue OptionParser::ParseError => err
    $stderr.puts err.message
    $stderr.puts parser.help
    exit 1
  end
  Automatic.core(recipe)
end
