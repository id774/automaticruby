# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Sort
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Mar 23, 2012
# Updated::   Jan 23, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.

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
          if @config['sort'] == "asc"
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
