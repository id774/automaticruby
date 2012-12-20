# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Tumblr
# Author::    774 <http://id774.net>
# Created::   Oct 16, 2012
# Updated::   Dec 20, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionTumblr
    require 'open-uri'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def create_rss(url)
      Automatic::Log.puts("info", "Parsing: #{url}")
      html = open(url).read
      unless html.nil?
        rss = Automatic::FeedParser.parse(html)
        sleep @config['interval'].to_i unless @config['internal'].nil?
        @return_feeds << rss
      end
    end

    def run
      @return_feeds = []
      @config['urls'].each {|url|
        begin
          create_rss(url)
        unless @config['pages'].nil?
          @config['pages'].times {|i|
            if i > 0
              old_url = url + "/page/" + (i+1).to_s
              create_rss(old_url)
            end
          }
        end
        rescue
          Automatic::Log.puts("error", "Fault in parsing: #{url}")
        end
      }
      @return_feeds
    end
  end
end
