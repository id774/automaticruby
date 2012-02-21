#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class SubscriptionFeed
  def initialize(config, pipeline=[])
    @config = config
    @pipeline = pipeline
  end

  def subscription
    @config['feeds'].each {|feed|
      begin
        Log.puts("info", "Parsing: #{feed}")
        rss_results = FeedParser.get_rss(feed)
        links = []
        rss_results.items.each do |item|
          links  << item.link
        end
        @pipeline << links
      rescue
        Log.puts("error", "Fault in parsing: #{feed}")
      end
    }
    @pipeline
  end

  def run
    subscription
  end
end
