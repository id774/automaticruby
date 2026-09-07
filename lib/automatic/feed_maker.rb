# -*- coding: utf-8 -*-
# Name::        Automatic::FeedMaker
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 21, 2014
# Updated::     Sep  7, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic
  module FeedMaker
    require 'rss'
    require 'uri'

    class FeedObject
      attr_accessor :title, :link, :description, :author, :comments
      def initialize
        @link        = nil
        @title       = nil
        @description = ''
        @author      = ''
        @comments    = ''
      end
    end

    def self.generate_feed(feed)
      feed_object = FeedObject.new
      feed_object.title = feed['title'] unless feed['title'].nil?
      feed_object.link = feed['url'] unless feed['url'].nil?
      feed_object.description = feed['description'] unless feed['description'].nil?
      feed_object.author = feed['author'] unless feed['author'].nil?
      feed_object.comments = feed['comments'] unless feed['comments'].nil?
      feed_object
    end

    # Plain-value standard fields, copied onto the rebuilt item as-is when the
    # item being rebuilt carries them. See doc/REQUIREMENTS.md and
    # doc/PLUGINS.md for the standard item field contract this preserves.
    REBUILD_SIMPLE_FIELDS = %i[title link description author comments content_encoded].freeze

    # source and enclosure are RSS child elements. RSS::Maker exposes each of
    # them on a new item as a builder with its own sub-attributes rather than
    # accepting the finished element directly, so each is rebuilt attribute by
    # attribute instead of by one assignment.
    REBUILD_STRUCTURED_FIELDS = {
      source:    %i[url content],
      enclosure: %i[url length type]
    }.freeze

    def self.create_pipeline(feeds = [])
      RSS::Maker.make("2.0") {|maker|
        xss = maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic::FeedMaker"
        maker.channel.link = "https://github.com/id774/automaticruby"
        maker.items.do_sort = true

        unless feeds.nil?
          feeds.each {|feed|
            Automatic::Log.puts("info", "Create Pipeline: #{feed.link}")
            item = maker.items.new_item
            item.date = (feed.pubDate if feed.respond_to?(:pubDate)) || Time.now

            REBUILD_SIMPLE_FIELDS.each { |field| copy_rebuild_field(feed, item, field) }
            REBUILD_STRUCTURED_FIELDS.each_key { |field| copy_rebuild_structured_field(feed, item, field) }
          }
        end
      }
    end

    def self.content_provide(url, data)
      RSS::Maker.make("2.0") {|maker|
        xss = maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic::FeedMaker"
        maker.channel.link = "https://github.com/id774/automaticruby"
        maker.items.do_sort = true
        item = maker.items.new_item
        item.title = "Automatic Ruby"
        item.link = url
        item.content_encoded = data
        item.date = Time.now
      }
    end

    # A field the item being rebuilt does not carry, or carries as nil, is
    # left off the new item: that is the normal shape of an optional field,
    # not a reason to skip copying anything else. See doc/POLICY.md on
    # distinguishing a missing optional value from a programming error.
    def self.copy_rebuild_field(feed, item, field)
      return unless feed.respond_to?(field)

      value = feed.public_send(field)
      return if value.nil?

      item.public_send("#{field}=", value)
    end
    private_class_method :copy_rebuild_field

    # source and enclosure are rebuilt sub-attribute by sub-attribute, on the
    # same missing-is-normal basis as copy_rebuild_field, so that (for
    # example) an enclosure with no type recorded still keeps its url.
    def self.copy_rebuild_structured_field(feed, item, field)
      return unless feed.respond_to?(field)

      value = feed.public_send(field)
      return if value.nil?

      target = item.public_send(field)
      REBUILD_STRUCTURED_FIELDS.fetch(field).each do |sub_field|
        next unless value.respond_to?(sub_field)

        sub_value = value.public_send(sub_field)
        target.public_send("#{sub_field}=", sub_value) unless sub_value.nil?
      end
    end
    private_class_method :copy_rebuild_structured_field
  end
end
