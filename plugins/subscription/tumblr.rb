# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Tumblr
# Author::    774 <http://id774.net>
# Created::   Oct 16, 2012
# Updated::   Oct 16, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionTumblr
    require 'open-uri'
    require 'nokogiri'
    require 'rss'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def create_rss(url)
      Automatic::Log.puts("info", "Parsing: #{url}")
      html = open(url).read
      unless html.nil?
        rss = RSS::Maker.make("2.0") {|maker|
          xss = maker.xml_stylesheets.new_xml_stylesheet
          xss.href = "http://www.rssboard.org/rss-specification"
          maker.channel.about = "http://feeds.rssboard.org/rssboard"
          maker.channel.title = "Automatic Ruby"
          maker.channel.description = "Automatic Ruby"
          maker.channel.link = "http://www.rssboard.org/rss-specification"
          maker.items.do_sort = true
          doc = Nokogiri::HTML(html)
          (doc/:a).each {|link|
            unless link[:href].nil?
              item = maker.items.new_item
              item.title = "Automatic Ruby"
              item.link = link[:href]
              item.date = Time.now
              item.description = "Automatic::Plugin::Subscription::Link"
            end
          }
        }
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
