# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Pocket
# Author::    soramugi <http://soramugi.net>
# Created::   May 21, 2013
# Updated::   May 21, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class DummyFeed
    def initialize(link,title,description)
      @title       = title
      @link        = link
      @description = description
    end

    def title() @title end
    def link() @link end
    def description() @description end
  end

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
      begin
        dummyfeeds = cleate_dummy_feed(@client.retrieve(@config['optional']))
        @pipeline << Automatic::FeedParser.create(dummyfeeds)
      rescue
        retries += 1
        Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in parsing: #{retries}")
        sleep @config['interval'].to_i unless @config['interval'].nil?
        retry if retries <= @config['retry'].to_i unless @config['retry'].nil?
      end

      @pipeline
    end

    def cleate_dummy_feed(retrieve)
      dummyFeeds = []
      retrieve['list'].each {|key,list|
        dummyFeeds << DummyFeed.new(
          list['given_url'], list['given_title'], list['excerpt']
        )
      }
      dummyFeeds
    end
  end
end
