# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::ImageSource
# Author::    774 <http://id774.net>
# Created::   Feb 28, 2012
# Updated::   Apr  5, 2013
# Copyright:: 774 Copyright (c) 2012-2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterImageSource
    require 'net/http'
    require 'kconv'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        dummyFeeds = Array.new
        unless feeds.nil?
          feeds.items.each {|feed|
            arr = rewrite_link(feed)
            if arr.length > 0
              arr.each {|link|
                Automatic::Log.puts("info", "Parsing: #{link}")
                dummy = Hashie::Mash.new
                dummy.title = 'FilterImageSource'
                dummy.link = link
                dummyFeeds << dummy
              }
            end
          }
        end
        @return_feeds << Automatic::FeedParser.create(dummyFeeds)
      }
      @pipeline = @return_feeds
    end

    private
    def rewrite_link(feed)
      array = Array.new
      feed.description.scan(/<img src="(.*?)"/) { |matched|
        array = array | matched
      }
      if array.length === 0 && feed.link != nil
        array = imgs(feed.link)
      end
      array
    end

    def imgs(link)
      images = Array.new
      html = open(link).read
      unless html.nil?
        doc = Nokogiri::HTML(html)
        (doc/:img).each {|img|
          image = img[:src]
          unless /^http/ =~ image
            image = link.sub(/\/([^\/]+)$/, image.sub(/^\./,''))
          end
          images << image
        }
      end
      images
    end
  end
end
