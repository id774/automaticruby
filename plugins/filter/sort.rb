# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Sort
# Author::    774 <http://id774.net>
# Created::   Mar 23, 2012
# Updated::   Jan 23, 2013
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterSort

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each { |feeds|
        return_feed_items = []
        unless feeds.nil?
          if @config['reverse'].nil?
            feeds.items.sort!{|a,b|
              a.date <=> b.date
            }
          else
            feeds.items.sort!{|a,b|
              - (a.date <=> b.date)
            }
          end
          @return_feeds << feeds
        end
      }
      @return_feeds
    end
  end
end
