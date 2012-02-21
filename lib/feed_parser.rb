#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

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
