# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::GGuide
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Jun 28, 2013
# Updated::   Oct 29, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.

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
      URI::Parser.new.escape(feed)
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
