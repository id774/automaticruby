# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Image
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Sep 18, 2012
# Updated::     Apr  5, 2013
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

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
