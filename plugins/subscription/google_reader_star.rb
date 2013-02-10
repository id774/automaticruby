# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::GoogleReaderStar
# Author::    soramugi <http://soramugi.net>
# Created::   Feb 10, 2013
# Updated::   Feb 10, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionGoogleReaderStar
    require 'open-uri'
    require 'nokogiri'
    require 'rss'

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @config['feeds'].each {|feed|
        begin
          Automatic::Log.puts("info", "Parsing: #{feed}")
          @return_feeds << self.parse(Automatic::FeedParser.get(feed).items)
        rescue
          Automatic::Log.puts("error", "Fault in parsing: #{feed}")
        end
      }
      @return_feeds
    end

    def parse(feeds = [])
      RSS::Maker.make("2.0") {|maker|
        maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic Ruby"
        maker.channel.link = "https://github.com/id774/automaticruby"
        maker.items.do_sort = true

        unless feeds.nil?
          feeds.each {|feed|
            unless feed.link.href.nil?
              Automatic::Log.puts("info", "Creating: #{feed.link.href}")
              item       = maker.items.new_item
              item.title = feed.title.content # google reader feed
              item.link  = feed.link.href     # google reader feed
              begin
                item.description = feed.description
                item.author      = feed.author
                item.comments    = feed.comments
                item.date        = feed.pubDate || Time.now
              rescue NoMethodError
                Automatic::Log.puts("warn", "Undefined field detected in feed.")
              end
            end
          }
        end
      }
    end

  end
end
