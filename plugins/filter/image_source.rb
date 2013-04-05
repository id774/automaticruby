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
        img_url = ""
        unless feeds.nil?
          feeds.items.each {|feed|
            arr = rewrite_link(feed.description)
            if arr.length > 0
              feed.link = arr[0]
            else
              feed.link = nil
            end
          }
        end
        @return_feeds << feeds
      }
      @return_feeds
    end

    private
    def rewrite_link(string)
      array = Array.new
      string.scan(/<img src="(.*?)"/) { |matched|
        array = array | matched
      }
      array
    end
  end
end
