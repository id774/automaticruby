# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::ImageSource
# Author::    774 <http://id774.net>
# Created::   Feb 28, 2012
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
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
        new_feeds = Array.new
        unless feeds.nil?
          feeds.items.each {|feed|
            arr = rewrite_link(feed)
            if arr.length > 0
              arr.each {|link|
                Automatic::Log.puts("info", "Parsing: #{link}")
                hashie = Hashie::Mash.new
                hashie.title = 'FilterImageSource'
                hashie.link = link
                new_feeds << hashie
              }
            end
          }
        end
        @return_feeds << Automatic::FeedMaker.create_pipeline(new_feeds)
      }
      @return_feeds
    end

    private

    def rewrite_link(feed)
      array = Array.new
      feed.description.scan(/<img src="(.*?)"/) {|matched|
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
