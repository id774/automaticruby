# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Rand
# Author::    soramugi <http://soramugi.net>
#             774 <http://id774.net>
# Created::   Mar  6, 2013
# Updated::   Mar  7, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterRand

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feed|
        unless feed.nil?
          @return_feeds << Automatic::FeedParser.create(feed.items.shuffle)
        end
      }
      @return_feeds
    end
  end
end
