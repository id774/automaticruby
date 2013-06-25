# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Sanitize
# Author::    774 <http://id774.net>
# Created::   Jun 20, 2013
# Updated::   Jun 24, 2013
# Copyright:: 774 Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterSanitize
    require 'sanitize'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      case @config['mode']
        when "basic"
          @mode = Sanitize::Config::BASIC
        when "relaxed"
          @mode = Sanitize::Config::RELAXED
        else
          @mode = Sanitize::Config::RESTRICTED
      end
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        return_feed_items = []
        unless feeds.nil?
          feeds.items.each {|feed|
            feed = sanitize(feed)
          }
          @return_feeds << feeds
        end
      }
      @return_feeds
    end

    private
    def sanitize(feed)
      begin
        feed.description = Sanitize.clean(feed.description, @mode) unless feed.description.nil?
        return feed
      rescue
        Automatic::Log.puts("warn", "Undefined field detected in feed.")
        return feed
      end
    end
  end
end
