# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::GGuide
# Author::    soramugi <http://soramugi.net>
#             774 <http://id774.net>
# Created::   Jun 28, 2013
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionGGuide
    G_GUIDE_RSS = 'http://tv.so-net.ne.jp/rss/schedulesBySearch.action?'

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
      unless @config['keyword'].nil? || @config['keyword'].index(',').nil?
        @keywords = @config['keyword'].split(',')
      else
        @keywords = [@config['keyword']]
      end
    end

    def run
      retries = 0
      retry_max = @config['retry'].to_i || 0
      begin
        @keywords.each {|keyword|
          @pipeline << Automatic::FeedParser.get_url(feed_url keyword)
        }
      rescue
        retries += 1
        Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in parsing: #{retries}")
        sleep ||= @config['interval'].to_i
        retry if retries <= retry_max
      end
      @pipeline
    end

    def feed_url keyword = nil
      feed = G_GUIDE_RSS
      unless keyword.nil?
        feed += "condition.keyword=#{keyword}&"
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
