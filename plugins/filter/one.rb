# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::One
# Author::    soramugi <http://soramugi.net>
#             774 <http://id774.net>
# Created::   May  8, 2013
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
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
          @return_feeds << Automatic::FeedMaker.create_pipeline(item)
        end
      }
      @return_feeds
    end
  end
end
