# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::GoogleNews
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Oct 12, 2014
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterGoogleNews
    require 'uri'

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
        @return_feeds << Automatic::FeedMaker.create_pipeline(new_feeds)
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

