#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Image
# Author::    774 <http://id774.net>
# Created::   Feb 28, 2012
# Updated::   Feb 28, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterImage
    require 'net/http'
    require 'kconv'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def parse_array(string)
      array = Array.new
      string.scan(/<img src="(.*?)"/) { |matched|
        array = array | matched
      }
      return array
    end

    def run
      return_feeds = []
      @pipeline.each {|feeds|
        img_url = ""
        unless feeds.nil?
          feeds.items.each {|feed|
            arr = parse_array(feed.description)
            if arr.length > 0
              feed.description = arr[0]
              Automatic::Log.puts("info", "Image: #{feed.description}")
            else
              feed.description = nil
            end
          }
        end
        return_feeds << feeds
      }
      return_feeds
    end
  end
end
