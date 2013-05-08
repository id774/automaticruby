# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::One
# Author::    soramugi <http://soramugi.net>
# Created::   May  8, 2013
# Updated::   May  8, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterOne

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feed|
        unless feed.nil?
          item = []
          unless @config.nil? or @config['pick'].nil?
            if @config['pick'] == 'last'
              item << feed.items.pop
            end
          end
          if item.count == 0
            item << feed.items.shift
          end
          @return_feeds << Automatic::FeedParser.create(item)
        end
      }
      @return_feeds
    end
  end
end
