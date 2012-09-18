# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Image
# Author::    774 <http://id774.net>
# Created::   Sep 18, 2012
# Updated::   Sep 18, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterImage

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        return_feed_items = []
        unless feeds.nil?
          feeds.items.each {|feed|
            unless feed.link.nil?
              image_link = nil
              feed.link.scan(/(.*?\.jp.*g$)/i) { |matched|
                image_link = matched.join(" ")
              }
              feed.link.scan(/(.*?\.png$)/i) { |matched|
                image_link = matched.join(" ")
              }
              feed.link.scan(/(.*?\.gif$)/i) { |matched|
                image_link = matched.join(" ")
              }
              feed.link.scan(/(.*?\.tiff$)/i) { |matched|
                image_link = matched.join(" ")
              }
              feed.link = image_link
            end
          }
          @return_feeds << feeds
        end
      }
      @return_feeds
    end
  end
end
