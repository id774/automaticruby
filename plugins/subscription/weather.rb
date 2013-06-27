# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Weather
# Author::    soramugi <http://soramugi.net>
# Created::   May 12, 2013
# Updated::   May 12, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
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
      weather = @weather.send(@day)['weather'] unless @weather.send(@day).nil?
      if weather != nil

        dummy       = Hashie::Mash.new
        dummy.title = weather
        dummy.link  = 'http://weather.dummy.' + @day
        @pipeline << Automatic::FeedParser.create([dummy])
      end

      @pipeline
    end
  end
end
