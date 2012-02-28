#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class AutoDiscovery
  require 'rubygems'
  require 'feedbag'

  def search(url)
    Feedbag.find(url)
  end
end

if __FILE__ == $0
  require 'pp'
  url = ARGV.shift || abort("Usage: autodiscovery.rb <url>")
  auto_discovery = AutoDiscovery.new
  pp auto_discovery.search(url)
end
