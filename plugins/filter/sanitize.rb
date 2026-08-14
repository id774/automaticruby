# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Sanitize
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Jun 20, 2013
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

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
        feed.description = Sanitize.fragment(feed.description, @mode) unless feed.description.nil?
      rescue
        Automatic::Log.puts("warn", "Undefined field detected in feed.")
      end
      feed
    end
  end
end
