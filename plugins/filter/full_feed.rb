# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::FullFeed
# Author::    progd <http://d.hatena.ne.jp/progd/20120429/automatic_ruby_filter_full_feed>
#             774 <http://id774.net>
# Created::   Apr 29, 2012
# Updated::   Jan 24, 2013
# Copyright:: progd
#             774 Copyright (c) 2012-2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin

  class FilterFullFeed
    require 'nokogiri'

    SITEINFO_TYPES = %w[SBM INDIVIDUAL IND SUBGENERAL SUB GENERAL GEN]

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @siteinfo = get_siteinfo
    end

    def get_siteinfo
      Automatic::Log.puts(:info, "Loading siteinfo from #{@config['siteinfo']}")
      siteinfo = JSON.load(open(File.join(assets_dir, @config['siteinfo'])).read)
      siteinfo.select! { |info| SITEINFO_TYPES.include? (info['data']['type']) }
      siteinfo.sort! { |a, b|
        atype, btype = a['data']['type'], b['data']['type']
        SITEINFO_TYPES.index(atype) <=> SITEINFO_TYPES.index(btype)
      }
      return siteinfo
    end

    def assets_dir
      dir = (File.expand_path('~/.automatic/assets/siteinfo'))
      if File.directory?(dir)
        dir
      else
        File.join(File.dirname(__FILE__), '..', '..', 'assets', 'siteinfo')
      end
    end

    def fulltext(feed)
      return feed unless feed.link
      @siteinfo.each { |info|
        if feed.link.match(info['data']['url'])
          Automatic::Log.puts(:info, "Siteinfo matched: #{info['data']['url']}")
          html = Nokogiri::HTML.parse(open(feed.link))
          body = html.xpath(info['data']['xpath'])
          feed.description = body.to_html.encode('UTF-8', :undef => :replace)
          return feed
        end
      }
      Automatic::Log.puts(:info, "Fulltext SITEINFO not found: #{feed.link}")
      return feed
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            feed = fulltext(feed)
          }
        end
        @return_feeds << feeds
      }
      @return_feeds
    end
  end
end
