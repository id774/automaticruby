#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class Log
  def self.puts(level, message)
    t = Time.now.strftime("%Y/%m/%d %X")
    print "#{t} [#{level}] #{message}\n"
  end
end

if __FILE__ == $0
  level = ARGV.shift || abort("Usage: log.rb <level> <message>")
  message = ARGV.shift
  Log.puts(level, message)
end
