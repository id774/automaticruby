# -*- coding: utf-8 -*-
# Name::      Automatic::FeedParser
# Author::    774 <http://id774.net>
# Created::   Feb 19, 2012
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.
#
# Fetching and parsing, on the way into the pipeline. What leaves here has the
# shape described in doc/PLUGINS.md section 3.4.

module Automatic
  module FeedParser
    require 'nokogiri'
    require 'open-uri'
    require 'rss'
    require 'uri'

    # Fetch a URL and parse it as a feed. Validation is off, because feeds in
    # the wild frequently are not valid and are still readable.
    def self.get_url(url)
      return if url.nil?

      Automatic::Log.puts('info', "Parsing Feed: #{url}")
      feed = URI.parse(url).normalize
      feed.open do |http|
        RSS::Parser.parse(http.read, false)
      end
    end

    # Build a feed whose items are the links of an HTML document. This is how
    # a page that publishes no feed enters the pipeline.
    def self.parse_html(html)
      RSS::Maker.make('2.0') do |maker|
        maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = 'Automatic Ruby'
        maker.channel.description = 'Automatic::FeedParser'
        maker.channel.link = 'https://github.com/id774/automaticruby'
        maker.items.do_sort = true

        doc = Nokogiri::HTML(html)
        (doc / :a).each do |link|
          next if link[:href].nil?

          item = maker.items.new_item
          item.title = 'Automatic Ruby'
          item.link = link[:href]
          item.date = Time.now
          item.description = ''
        end
      end
    end
  end
end
