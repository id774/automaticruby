#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Feed
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 22, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

class SubscriptionFeed
  def initialize(config, pipeline=[])
    @config = config
    @pipeline = pipeline
  end

  def run
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
end
