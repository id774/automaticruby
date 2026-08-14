# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::AbsoluteURI
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 20, 2012
# Updated::     Oct 29, 2014
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterAbsoluteURI

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            feed.link = rewrite(feed.link) unless feed.link.nil?
          }
          @return_feeds << feeds
        end
      }
      @return_feeds
    end

    private
    def rewrite(string)
      if /^http:\/\/.*$/ =~ string
        return string
      end

      if /[^\/]$/ =~ @config['url']
        @config['url'] = @config['url'] + '/'
      end
      string = @config['url'] + string.sub(/^\./,'').sub(/^\//,'')
      string = URI::Parser.new.escape(string)
      return string
    end
  end
end
