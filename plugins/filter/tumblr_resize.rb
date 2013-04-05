# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::TumblrResize
# Author::    774 <http://id774.net>
# Created::   Feb 28, 2012
# Updated::   Apr  5, 2013
# Copyright:: 774 Copyright (c) 2012-2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterTumblrResize

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        img_url = ""
        unless feeds.nil?
          feeds.items.each {|feed|
            feed.link = resize(feed.link) unless feed.link.nil?
          }
        end
        @return_feeds << feeds
      }
      @return_feeds
    end

    private
    def resize(string)
      string = string.gsub("_75sq\.", "_1280\.")
      string = string.gsub("_100\.", "_1280\.")
      string = string.gsub("_250\.", "_1280\.")
      string = string.gsub("_400\.", "_1280\.")
      string = string.gsub("_500\.", "_1280\.")
    end
  end
end
