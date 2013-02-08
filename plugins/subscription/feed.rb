# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::SubscriptionFeed
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb  8, 2013
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
        retries = 0
        begin
          rss = Automatic::FeedParser.get(feed)
          @pipeline << rss
        rescue
          retries += 1
          Automatic::Log.puts("error", "Fault in parsing: #{feed}")
          sleep @config['interval'].to_i unless @config['interval'].nil?
          retry if retries <= @config['retry'].to_i unless @config['retry'].nil?
        end
      }
      @pipeline
    end
  end
end
