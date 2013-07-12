# -*- coding: utf-8 -*-
# Name::      Automatic::FeedParser
# Author::    774 <http://id774.net>
# Created::   Feb 19, 2012
# Updated::   Jul 12, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic
  module FeedParser
    require 'rss'
    require 'uri'
    require 'nokogiri'

    def self.get(url)
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

    def self.create(feeds = [])
      RSS::Maker.make("2.0") {|maker|
        xss = maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic Ruby"
        maker.channel.link = "https://github.com/automaticruby/automaticruby"
        maker.items.do_sort = true

        unless feeds.nil?
          feeds.each {|feed|
            unless feed.link.nil?
              Automatic::Log.puts("info", "Feed: #{feed.link}")
              item = maker.items.new_item
              item.title = feed.title
              item.link = feed.link
              begin
                item.description = feed.description
                item.author = feed.author
                item.comments = feed.comments
                item.date = feed.pubDate || Time.now
              rescue NoMethodError
                Automatic::Log.puts("warn", "Undefined field detected in feed.")
              end
            end
          }
        end
      }
    end

    def self.parse(html)
      RSS::Maker.make("2.0") {|maker|
        xss = maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic Ruby"
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

    def self.content_provide(url, data)
      RSS::Maker.make("2.0") {|maker|
        xss = maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic Ruby"
        maker.channel.link = "https://github.com/automaticruby/automaticruby"
        maker.items.do_sort = true
        item = maker.items.new_item
        item.title = "Automatic Ruby"
        item.link = url
        item.content_encoded = data
        item.date = Time.now
      }
    end
  end
end
