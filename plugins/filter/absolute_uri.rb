# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::AbsoluteURI
# Author::    774 <http://id774.net>
# Created::   Jun 20, 2012
# Updated::   Apr  5, 2013
# Copyright:: 774 Copyright (c) 2012-2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterAbsoluteURI

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
            feed.link = rewrite(feed.link) unless feed.link.nil?
          }
          @return_feeds << feeds
        end
      }
      @return_feeds
    end

    private
    def rewrite(string)
      if /^http:\/\/.*$/ =~ string
        return string
      else
        return @config['url'] + string
      end
    end
  end
end
