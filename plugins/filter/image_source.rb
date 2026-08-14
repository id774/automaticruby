# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::ImageSource
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 28, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterImageSource
    require 'net/http'
    Automatic.require_optional('nokogiri', needed_by: 'FilterImageSource')
    require 'open-uri'
    require 'uri'

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
                Automatic::Log.puts("info", "Extract Image: #{link}")
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
      html = URI.open(link).read
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
