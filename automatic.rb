#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
basedir = File.dirname(__FILE__)
$:.unshift File.join(basedir, 'lib')
$:.unshift File.join(basedir, 'plugins')

Dir.glob(basedir + '/lib/*.rb').each {|r|
  require(File.basename(r, '.rb'))
}
Dir.glob(basedir + '/plugins/*.rb').each {|r|
  require(File.basename(r, '.rb'))
}

filename = ""
require 'optparse'
parser = OptionParser.new do |parser|
  parser.version = "12.02-devel"
  parser.banner = "#{File.basename($0,".*")}
  Usage: #{File.basename($0,".*")} [options] arg"
  parser.separator "options:"
  parser.on('-c', '--config FILE', String,
            "read data from FILENAME"){|f| filename = f}
  parser.on('-h', '--help', "show this message"){
    puts parser
    exit
  }
end

begin
  parser.parse!
rescue OptionParser::ParseError => err
  $stderr.puts err.message
  $stderr.puts parser.help
  exit 1
end

require 'yaml'
require 'pp'
if filename == ""
  filename = basedir + '/config/default.yml'
end

print "Loading #{filename}\n"
File.open(filename) {|io|
  YAML.load_documents(io) {|yaml|
    yaml['plugins'].each {|plugin|
      loader = eval(plugin['module']).new(plugin['config'])
      loader.run
    }
  }
}
