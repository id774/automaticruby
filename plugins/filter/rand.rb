# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Rand
# Author::    soramugi <http://soramugi.net>
#             774 <http://id774.net>
# Created::   Mar  6, 2013
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
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
          @return_feeds << Automatic::FeedMaker.create_pipeline(feed.items.shuffle)
        end
      }
      @return_feeds
    end
  end
end
