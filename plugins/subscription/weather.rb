# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Weather
# Author::    soramugi <http://soramugi.net>
# Created::   May 12, 2013
# Updated::   May 12, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class WeatherFeed
    def initialize
      @link  = 'http://weather.dummy'
      @title = 'weather-dummy'
    end

    def link
      @link
    end

    def title
      @title
    end

    def set_link(link)
      @link = link
    end

    def set_title(title)
      @title = title
    end
  end

  class SubscriptionWeather
    require 'weather_hacker'

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
      @weather  = WeatherHacker.new(@config['zipcode'])
      @day      = 'today'
      @day      = @config['day'] unless @config['day'].nil?
    end

    def run
      retries = 0
      begin
        weather = @weather.send(@day)['weather'] unless @weather.send(@day).nil?
        if weather != nil
          dummyfeed = WeatherFeed.new
          dummyfeed.set_title(weather)
          dummyfeed.set_link(dummyfeed.link + '.' + @day)
          dummyfeeds = []
          dummyfeeds << dummyfeed
          @pipeline << Automatic::FeedParser.create(dummyfeeds)
        end
      rescue
        retries += 1
        Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in parsing: #{dummyfeed}")
        sleep @config['interval'].to_i unless @config['interval'].nil?
        retry if retries <= @config['retry'].to_i unless @config['retry'].nil?
      end

      @pipeline
    end
  end
end
