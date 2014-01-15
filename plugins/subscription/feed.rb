# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::SubscriptionFeed
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Jan 15, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
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
        retry_max = @config['retry'].to_i || 0
        begin
          rss = Automatic::FeedParser.get(feed)
          @pipeline << rss
        rescue
          retries += 1
          Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in parsing: #{feed}")
          sleep ||= @config['interval'].to_i
          retry if retries <= retry_max
        end
      }
      @pipeline
    end
  end
end
