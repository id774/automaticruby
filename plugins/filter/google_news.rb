# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::GoogleNews
# Author::    774 <http://id774.net>
# Created::   Oct 12, 2014
# Updated::   Oct 16, 2014
# Copyright:: Copyright (c) 2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterGoogleNews
    require 'uri'
    require 'nkf'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        new_feeds = []
        unless feeds.nil?
          feeds.items.each {|feed|
            new_feeds << rewrite_link(feed) unless feed.link.nil?
          }
        end
        @return_feeds << new_feeds
      }
      @return_feeds
    end

    private

    def rewrite_link(feed)
      if feed.link.class == String
        if feed.link.index("http://news.google.com")
          matched = feed.link.match(/(&url=)/)
          unless matched.nil?
            new_link = matched.post_match
            feed.link = new_link unless new_link.nil?
          end
        end
      end

      feed
    end
  end
end

