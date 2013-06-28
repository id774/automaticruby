# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::GGuide
# Author::    soramugi <http://soramugi.net>
# Created::   Jun 28, 2013
# Updated::   Jun 28, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionGGuide
    G_GUIDE_RSS = 'http://tv.so-net.ne.jp/rss/schedulesBySearch.action?'

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
    end

    def run
      retries = 0
      begin
        @pipeline << Automatic::FeedParser.get(feed_url)
      rescue
        retries += 1
        Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in parsing: #{retries}")
        sleep @config['interval'].to_i unless @config['interval'].nil?
        retry if retries <= @config['retry'].to_i unless @config['retry'].nil?
      end

      @pipeline
    end

    def feed_url
        feed = G_GUIDE_RSS
        unless @config['keyword'].nil?
          feed += "condition.keyword=#{@config['keyword']}&"
        end
        feed += station_param
        URI.encode(feed)
    end

    def station_param
        station = 0
        unless @config['station'].nil?
          station = '1' if @config['station'] == '地上波'
        end
        "stationPlatformId=#{station}&"
    end
  end
end
