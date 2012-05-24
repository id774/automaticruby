#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Link
# Author::    774 <http://id774.net>
# Created::   May 24, 2012
# Updated::   May 24, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterLink
    require 'hpricot'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      return_feeds = []
      @pipeline.each {|feeds|
        img_url = ""
        unless feeds.nil?
          doc = Hpricot(feeds)
          (doc/:a).each {|link|
            return_feeds << link[:href]
          }
        end
      }
      return_feeds
    end
  end
end
