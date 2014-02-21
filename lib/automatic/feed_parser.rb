# -*- coding: utf-8 -*-
# Name::      Automatic::FeedParser
# Author::    774 <http://id774.net>
# Created::   Feb 19, 2012
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic
  module FeedParser
    require 'rss'
    require 'uri'
    require 'nokogiri'

    def self.get_url(url)
      begin
        unless url.nil?
          Automatic::Log.puts("info", "Parsing: #{url}")
          feed = URI.parse(url).normalize
          open(feed) {|http|
            response = http.read
            RSS::Parser.parse(response, false)
          }
        end
      rescue => e
        raise e
      end
    end

    def self.parse_html(html)
      RSS::Maker.make("2.0") {|maker|
        xss = maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic::FeedParser"
        maker.channel.link = "https://github.com/automaticruby/automaticruby"
        maker.items.do_sort = true

        doc = Nokogiri::HTML(html)
        (doc/:a).each {|link|
          unless link[:href].nil?
            item = maker.items.new_item
            item.title = "Automatic Ruby"
            item.link = link[:href]
            item.date = Time.now
            item.description = ""
          end
        }
      }
    end
  end
end
