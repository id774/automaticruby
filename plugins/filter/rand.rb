# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Rand
# Author: soramugi (More info: http://soramugi.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Mar  6, 2013
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.

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
