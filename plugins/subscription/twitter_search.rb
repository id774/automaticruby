# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::TwitterSearch
# Author::    soramugi <http://soramugi.net>
# Created::   May 30, 2013
# Updated::   May 30, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionTwitterSearch
    require 'twitter'

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
      @client = Twitter::Client.new(
        :consumer_key       => @config['consumer_key'],
        :consumer_secret    => @config['consumer_secret'],
        :oauth_token        => @config['oauth_token'],
        :oauth_token_secret => @config['oauth_token_secret']
      )
    end

    def run
      @pipeline = []
      retries = 0
      begin
        feeds = []
        @client.search(@config['search'],@config['opt']).results.each do |status|

          dummy             = Hashie::Mash.new
          dummy.title       = 'Twitter Search'
          dummy.link        = "https://twitter.com/#{status.user['screen_name']}/status/#{status.id}"
          dummy.description = status.text
          dummy.author      = status.user['screen_name']
          dummy.date        = status.created_at

          feeds << dummy
        end
        @pipeline << Automatic::FeedParser.create(feeds)
      rescue
        retries += 1
        Automatic::Log.puts("error", "ErrorCount: #{retries}")
        sleep @config['interval'].to_i unless @config['interval'].nil?
        retry if retries <= @config['retry'].to_i unless @config['retry'].nil?
      end
      @pipeline
    end
  end
end
