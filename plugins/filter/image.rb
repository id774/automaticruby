# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Image
# Author::    774 <http://id774.net>
# Created::   Sep 18, 2012
# Updated::   Apr  5, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
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
            feed.link = image?(feed.link) unless feed.link.nil?
          }
          @return_feeds << feeds
        end
      }
      @return_feeds
    end

    private
    def image?(link)
      case link
        when /\.jpe?g\Z/i then link
        when /\.gif\Z/i then link
        when /\.png\Z/i then link
        when /\.tiff\Z/i then link
        else nil
      end
    end
  end
end
