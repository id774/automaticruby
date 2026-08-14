# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::SubscriptionFeed
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 22, 2012
# Updated::     Feb 21, 2014
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

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
          rss = Automatic::FeedParser.get_url(feed)
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
