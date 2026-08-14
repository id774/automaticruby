# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::FullFeed
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Apr 29, 2012
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin

  class FilterFullFeed
    require 'json'
    require 'nokogiri'
    require 'open-uri'
    require 'uri'

    SITEINFO_TYPES = %w[SBM INDIVIDUAL IND SUBGENERAL SUB GENERAL GEN]

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @siteinfo = get_siteinfo
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

    private

    def get_siteinfo
      Automatic::Log.puts(:info, "Loading siteinfo from #{@config['siteinfo']}")
      siteinfo = JSON.parse(File.read(File.join(assets_dir, @config['siteinfo']), :encoding => "UTF-8"))
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
      @siteinfo.each {|info|
        begin
          if feed.link.match(info['data']['url'])
            Automatic::Log.puts(:info, "Siteinfo matched: #{info['data']['url']}")
            html = Nokogiri::HTML.parse(URI.open(feed.link))
            body = html.xpath(info['data']['xpath'])
            feed.description = body.to_html.encode('UTF-8', :undef => :replace)
            return feed
          end
        rescue
          return feed
        end
      }
      Automatic::Log.puts(:info, "Fulltext SITEINFO not found: #{feed.link}")
      return feed
    end
  end
end
