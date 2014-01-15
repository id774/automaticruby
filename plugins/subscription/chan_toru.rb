# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::ChanToru
# Author::    soramugi <http://soramugi.net>
# Created::   Jun 28, 2013
# Updated::   Jun 28, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '/g_guide')

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
        retry_max = @config['retry'].to_i || 0
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
