# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Text
# Author::    soramugi <http://soramugi.net>
#             774 <http://id774.net>
# Created::   May  6, 2013
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionText
    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
      @return_feeds = []
    end

    def run
      create_feed
      @pipeline << Automatic::FeedMaker.create_pipeline(@return_feeds) if @return_feeds.length > 0
      @pipeline
    end

    private

    def create_feed
      unless @config.nil?
        @dummyfeeds = []
        unless @config['titles'].nil?
          @config['titles'].each {|title|
            feed = {}
            feed['title'] = title
            @return_feeds << Automatic::FeedMaker.generate_feed(feed)
          }
        end

        unless @config['urls'].nil?
          @config['urls'].each {|url|
            feed = {}
            feed['url'] = url
            @return_feeds << Automatic::FeedMaker.generate_feed(feed)
          }
        end

        unless @config['feeds'].nil?
          @config['feeds'].each {|feed|
            @return_feeds << Automatic::FeedMaker.generate_feed(feed)
          }
        end

        unless @config['files'].nil?
          @config['files'].each {|f|
            open(File.expand_path(f)) do |file|
              file.each_line do |line|
                feed = {}
                feed['title'], feed['url'], feed['description'], feed['author'],
                feed['comments'] = line.force_encoding("utf-8").strip.split("\t")
                @return_feeds << Automatic::FeedMaker.generate_feed(feed)
              end
            end
          }
        end
      end
    end

  end
end
