# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::TwitterSearch
# Author::    soramugi <http://soramugi.net>
# Created::   May 30, 2013
# Updated::   Jan 15, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
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
      retry_max = @config['retry'].to_i || 0
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
        sleep ||= @config['interval'].to_i
        retry if retries <= retry_max
      end
      @pipeline
    end
  end
end
