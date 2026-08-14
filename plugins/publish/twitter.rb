# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Twitter
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   May  5, 2013
# Updated::   May  5, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishTwitter
    require 'twitter'

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline

      Twitter.configure do |conf|
        conf.consumer_key       = @config['consumer_key']
        conf.consumer_secret    = @config['consumer_secret']
        conf.oauth_token        = @config['oauth_token']
        conf.oauth_token_secret = @config['oauth_token_secret']
      end
      @twitter = Twitter

      if @config['tweet_tmp'] == nil
        @tweet_tmp = '{title} {link}'
      else
        @tweet_tmp = @config['tweet_tmp']
      end

    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            Automatic::Log.puts("info", "Publish Tweet: #{feed.link}")
            retries = 0
            retry_max = @config['retry'].to_i || 0
            begin
              tweet = @tweet_tmp.gsub(/\{(.+?)\}/) do |text|
                feed.__send__($1)
              end
              @twitter.update(tweet)
            rescue
              retries += 1
              Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in publish to twitter.")
              sleep ||= @config['interval'].to_i
              retry if retries <= retry_max
            end
            sleep ||= @config['interval'].to_i
          }
        end
      }
      @pipeline
    end
  end
end
