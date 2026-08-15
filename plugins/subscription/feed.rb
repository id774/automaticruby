# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::SubscriptionFeed
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 22, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class SubscriptionFeed
    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    def run
      Array(@config['feeds']).each do |url|
        feed = fetch(url)
        @pipeline << feed unless feed.nil?
      end
      @pipeline
    end

    private

    # A feed that fails after its retries is logged and skipped; the others
    # still run.
    def fetch(url)
      retries   = 0
      retry_max = @config['retry'].to_i
      begin
        Automatic::FeedParser.get_url(url)
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
