# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Rand
# Author::    soramugi <http://soramugi.net>
# Created::   Mar  6, 2013
# Updated::   Mar  6, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterRand

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each { |feed|
        unless feed.nil?
          @return_feeds << Automatic::FeedParser.create(feed.items.sort_by{rand})
        end
      }
      @return_feeds
    end
  end
end
