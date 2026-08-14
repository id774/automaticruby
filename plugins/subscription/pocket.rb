# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Pocket
# Author: soramugi (More info: http://soramugi.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   May 21, 2013
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.

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
        return_feeds = generate_feed(@client.retrieve(@config['optional']))
        @pipeline << Automatic::FeedMaker.create_pipeline(return_feeds)
      rescue
        retries += 1
        Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in parsing: #{retries}")
        sleep ||= @config['interval'].to_i
        retry if retries <= retry_max
      end
      @pipeline
    end

    def generate_feed(retrieve)
      return_feeds = []
      retrieve['list'].each {|key,list|
        hashie             = Hashie::Mash.new
        hashie.title       = list['given_title']
        hashie.link        = list['given_url']
        hashie.description = list['excerpt']
        return_feeds << hashie
      }
      return_feeds
    end
  end
end
