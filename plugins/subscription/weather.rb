# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Weather
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   May 12, 2013
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.

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
        hashie       = Hashie::Mash.new
        hashie.title = weather
        hashie.link  = 'http://weather.dummy.' + @day
        @pipeline << Automatic::FeedMaker.create_pipeline([hashie])
      end
      @pipeline
    end
  end
end
