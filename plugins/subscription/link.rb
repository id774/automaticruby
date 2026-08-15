# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::Link
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Sep 18, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class SubscriptionLink
    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Returns only what it fetched, discarding any incoming pipeline.
    def run
      Array(@config['urls']).each_with_object([]) do |url, feeds|
        rss = fetch(url)
        feeds << rss unless rss.nil?
      end
    end

    private

    def fetch(url)
      retries   = 0
      retry_max = @config['retry'].to_i
      begin
        Automatic::Log.puts('info', "Parsing Link: #{url}")
        rss = Automatic::FeedParser.parse_html(Automatic::Http.read(url))
        sleep(@config['interval'].to_i)
        rss
      rescue StandardError => e
        retries += 1
        Automatic::Log.puts('error',
                            "ErrorCount: #{retries}, Fault in parsing: #{url}, #{e.message}")
        return nil if retries > retry_max

        sleep(@config['interval'].to_i)
        retry
      end
    end
  end
end
