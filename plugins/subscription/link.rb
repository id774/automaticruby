# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::Link
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Sep 18, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class SubscriptionLink
    require 'open-uri'
    require 'rss'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @config['urls'].each {|url|
        retries = 0
        retry_max = @config['retry'].to_i || 0
        begin
          create_rss(URI::RFC2396_Parser.new.escape(url))
        rescue
          retries += 1
          Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in parsing: #{url}")
          sleep ||= @config['interval'].to_i
          retry if retries <= retry_max
        end
      }
      @return_feeds
    end

    private

    def create_rss(url)
      Automatic::Log.puts("info", "Parsing Link: #{url}")
      html = URI.open(url).read
      unless html.nil?
        rss = Automatic::FeedParser.parse_html(html)
        sleep ||= @config['interval'].to_i
        @return_feeds << rss
      end
    end
  end
end
