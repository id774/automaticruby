#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::SubscriptionFeed
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 24, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionFeed
    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @config['feeds'].each {|feed|
        begin
          Automatic::Log.puts("info", "Parsing: #{feed}")
          rss = Automatic::FeedParser.get_rss(feed)
          @pipeline << rss
        rescue
          Automatic::Log.puts("error", "Fault in parsing: #{feed}")
        end
      }
      @pipeline
    end
  end
end
