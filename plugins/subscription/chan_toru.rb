# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::ChanToru
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 28, 2013
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require_relative 'g_guide'

module Automatic::Plugin
  class SubscriptionChanToru

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
    end

    def g_guide_pipeline
      SubscriptionGGuide.new(@config, @pipeline).run
    end

    def run
      retries = 0
      retry_max = @config['retry'].to_i || 0
      begin
        pipeline = g_guide_pipeline
        pipeline.each {|feeds|
          feeds.items.each {|feed|
            feed = link_change(feed)
          }
        }
        @pipeline = pipeline
      rescue
        retries += 1
        Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in parsing: #{retries}")
        sleep ||= @config['interval'].to_i
        retry if retries <= retry_max
      end

      @pipeline
    end

    def link_change(feed)
      feed.link.gsub(/([0-9]+)/) do |pid|
        if pid != ''
          feed.link = "https://tv.so-net.ne.jp/chan-toru/intent" +
            "?cat=1&area=23&pid=#{pid}&from=tw"
        else
          feed.link = nil
        end
      end
      feed
    end

  end
end
