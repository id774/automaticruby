# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Pocket
# Author::    soramugi <http://soramugi.net>
# Created::   May 21, 2013
# Updated::   Jan 15, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionPocket
    require 'pocket'

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
      Pocket.configure do |c|
        c.consumer_key = @config['consumer_key']
        c.access_token = @config['access_token']
      end
      @client = Pocket.client
    end

    def run
      retries = 0
      retry_max = @config['retry'].to_i || 0
      begin
        dummyfeeds = cleate_dummy_feed(@client.retrieve(@config['optional']))
        @pipeline << Automatic::FeedParser.create(dummyfeeds)
      rescue
        retries += 1
        Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in parsing: #{retries}")
        sleep ||= @config['interval'].to_i
        retry if retries <= retry_max
      end
      @pipeline
    end

    def cleate_dummy_feed(retrieve)
      dummyFeeds = []
      retrieve['list'].each {|key,list|
        dummy             = Hashie::Mash.new
        dummy.title       = list['given_title']
        dummy.link        = list['given_url']
        dummy.description = list['excerpt']
        dummyFeeds << dummy
      }
      dummyFeeds
    end
  end
end
