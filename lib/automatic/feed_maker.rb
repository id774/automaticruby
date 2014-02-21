# -*- coding: utf-8 -*-
# Name::      Automatic::FeedMaker
# Author::    774 <http://id774.net>
# Created::   Feb 21, 2014
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic
  module FeedMaker
    require 'rss'
    require 'uri'
    require 'nokogiri'

    class FeedObject
      attr_accessor :title, :link, :description, :author, :comments
      def initialize
        @link        = 'http://dummy'
        @title       = 'dummy'
        @description = ''
        @author      = ''
        @comments    = ''
      end
    end

    def self.generate_feed(feed)
      feed_object = FeedObject.new
      feed_object.title = feed['title'] unless feed['title'].nil?
      feed_object.link = feed['url'] unless feed['url'].nil?
      feed_object.description = feed['description'] unless feed['description'].nil?
      feed_object.author = feed['author'] unless feed['author'].nil?
      feed_object.comments = feed['comments'] unless feed['comments'].nil?
      feed_object
    end

    def self.create_pipeline(feeds = [])
      RSS::Maker.make("2.0") {|maker|
        xss = maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic::FeedMaker"
        maker.channel.link = "https://github.com/automaticruby/automaticruby"
        maker.items.do_sort = true

        unless feeds.nil?
          feeds.each {|feed|
            unless feed.link.nil?
              Automatic::Log.puts("info", "Feed: #{feed.link}")
              item = maker.items.new_item
              item.title = feed.title
              item.link = feed.link
              begin
                item.description = feed.description
                item.author = feed.author
                item.comments = feed.comments
                item.date = feed.pubDate || Time.now
              rescue NoMethodError
                Automatic::Log.puts("warn", "Undefined field detected in feed.")
              end
            end
          }
        end
      }
    end

    def self.content_provide(url, data)
      RSS::Maker.make("2.0") {|maker|
        xss = maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic::FeedMaker"
        maker.channel.link = "https://github.com/automaticruby/automaticruby"
        maker.items.do_sort = true
        item = maker.items.new_item
        item.title = "Automatic Ruby"
        item.link = url
        item.content_encoded = data
        item.date = Time.now
      }
    end
  end
end
