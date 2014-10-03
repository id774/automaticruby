# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::DescriptionLink
# Author::    774 <http://id774.net>
# Created::   Oct 03, 2014
# Updated::   Oct 03, 2014
# Copyright:: Copyright (c) 2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterDescriptionLink
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
            new_feeds << rewrite_link(feed)
          }
        end
        @return_feeds << Automatic::FeedMaker.create_pipeline(new_feeds)
      }
      @return_feeds
    end

    private

    def rewrite_link(feed)
      new_link = URI.extract(feed.description, %w{http https}).uniq.last
      feed.link = new_link unless new_link.nil?
      feed
    end
  end
end

