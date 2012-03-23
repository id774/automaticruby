#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Reverse
# Author::    774 <http://id774.net>
# Created::   Mar 23, 2012
# Updated::   Mar 23, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterReverse

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @output = STDOUT
    end

    def run
      return_feeds = []
      @pipeline.each { |feeds|
        return_feed_items = []
        unless feeds.nil?
          feeds.items.sort!{|a,b|
            a.date <=> b.date
          }
          return_feeds << feeds
        end
      }
      return_feeds
    end
  end
end
