#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$:.unshift File.join(File.dirname(__FILE__), 'lib')
$:.unshift File.join(File.dirname(__FILE__), 'plugins')

Dir.glob(File.dirname(__FILE__) + '/lib/*.rb').each {|r|
  require(File.basename(r, '.rb'))
}
Dir.glob(File.dirname(__FILE__) + '/plugins/*.rb').each {|r|
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
            "read data from FILENAME"){|f| filename = f }
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
if filename == ""
  config = YAML.load(File.open(File.dirname(__FILE__) + '/config/default.yml'))
else
  print "Loading #{filename}\n"
  config = YAML.load(File.open(filename))
end
loader = eval(config['plugins']['module']).new(config)
loader.run
