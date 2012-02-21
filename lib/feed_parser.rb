#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::FeedParser
# Author::    774 <http://id774.net>
# Created::   Feb 19, 2012
# Updated::   Feb 22, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

class FeedParser
  require 'rss'
  require 'uri'

  def self.get_rss(url)
    begin
      unless url.nil?
        feed = URI.parse(url).normalize
        open(feed) do |http|
          response = http.read
          RSS::Parser.parse(response, false)
        end
      end
    rescue => e
      raise e
    end
  end
end

if __FILE__ == $0
  url = ARGV.shift || abort("Usage: feed_parser.rb <url>")
  rss_results = FeedParser.get_rss(url)
  require 'pp'
  pp links
end
