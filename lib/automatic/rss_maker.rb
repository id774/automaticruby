# -*- coding: utf-8 -*-
# Name::      Automatic::RSSMaker
# Author::    774 <http://id774.net>
# Created::   Dec 20, 2012
# Updated::   Dec 20, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic
  module RSSMaker
    def self.create(feeds)
      RSS::Maker.make("2.0") {|maker|
        xss = maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic Ruby"
        maker.channel.link = "https://github.com/id774/automaticruby"
        maker.items.do_sort = true
        unless feeds.nil?
          feeds.each {|feed|
            unless feed.link.nil?
              item = maker.items.new_item
              item.title = feed.title
              item.link = feed.link
              item.description = feed.description
              item.author = feed.author
              item.comments = feed.comments
              item.date = feed.pubDate || Time.now
            end
          }
        end
      }
    end
  end
end
