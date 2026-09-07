# -*- coding: utf-8 -*-
# Name::        Automatic::FeedMaker
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Sep  6, 2026
# Updated::     Sep  7, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# create_pipeline rebuilds each item it is given into a new RSS feed. This is
# the direct regression test for that rebuild keeping the standard item field
# contract doc/REQUIREMENTS.md and doc/PLUGINS.md describe, rather than
# quietly dropping source, enclosure or content_encoded on the way through, as
# it used to.

require File.expand_path(File.join(File.dirname(__FILE__), '../../spec_helper'))

require 'automatic/feed_maker'

describe Automatic::FeedMaker do
  describe ".generate_feed" do
    it "leaves link absent when only a title is given" do
      item = Automatic::FeedMaker.generate_feed("title" => "A title")

      item.title.should == "A title"
      item.link.should be_nil
    end

    it "leaves title absent when only a URL is given" do
      item = Automatic::FeedMaker.generate_feed("url" => "https://example.com/a")

      item.title.should be_nil
      item.link.should == "https://example.com/a"
    end
  end

  describe ".create_pipeline" do
    # Builds a pipeline item the way FeedParser or a previous create_pipeline
    # call would hand one on: a real RSS::Rss::Channel::Item, with real
    # Source/Enclosure objects where one is given, and every field left unset
    # (rather than set to an empty placeholder) where it is not.
    def build_item(link: "https://example.com/a", title: "A title",
                    description: "A description", author: "jdoe",
                    comments: "https://example.com/a#comments",
                    date: Time.parse("2020-01-01T00:00:00Z"),
                    source: nil, enclosure: nil, content_encoded: nil)
      item = RSS::Rss::Channel::Item.new
      item.link = link
      item.title = title
      item.description = description unless description.nil?
      item.author = author unless author.nil?
      item.comments = comments unless comments.nil?
      item.pubDate = date unless date.nil?
      item.source = source unless source.nil?
      item.enclosure = enclosure unless enclosure.nil?
      item.content_encoded = content_encoded unless content_encoded.nil?
      item
    end

    let(:source) {
      RSS::Rss::Channel::Item::Source.new("https://example.com/feed.xml", "Example Feed")
    }

    let(:enclosure) {
      RSS::Rss::Channel::Item::Enclosure.new("https://example.com/a.mp3", 123, "audio/mpeg")
    }

    it "preserves title, link, description, author and comments" do
      rebuilt = Automatic::FeedMaker.create_pipeline([build_item])
      item = rebuilt.items.first

      item.title.should == "A title"
      item.link.should == "https://example.com/a"
      item.description.should == "A description"
      item.author.should == "jdoe"
      item.comments.should == "https://example.com/a#comments"
    end

    it "preserves the existing date rather than replacing it with the current time" do
      old_date = Time.parse("2001-02-03T04:05:06Z")
      rebuilt = Automatic::FeedMaker.create_pipeline([build_item(date: old_date)])

      rebuilt.items.first.date.should == old_date
    end

    it "preserves source" do
      rebuilt = Automatic::FeedMaker.create_pipeline([build_item(source: source)])
      item = rebuilt.items.first

      item.source.should_not be_nil
      item.source.url.should == "https://example.com/feed.xml"
      item.source.content.should == "Example Feed"
    end

    it "preserves enclosure" do
      rebuilt = Automatic::FeedMaker.create_pipeline([build_item(enclosure: enclosure)])
      item = rebuilt.items.first

      item.enclosure.should_not be_nil
      item.enclosure.url.should == "https://example.com/a.mp3"
      item.enclosure.length.should == 123
      item.enclosure.type.should == "audio/mpeg"
    end

    it "preserves content_encoded" do
      rebuilt = Automatic::FeedMaker.create_pipeline(
        [build_item(content_encoded: "<p>Full body</p>")]
      )

      rebuilt.items.first.content_encoded.should == "<p>Full body</p>"
    end

    it "preserves source, enclosure and content_encoded together on the same item" do
      rebuilt = Automatic::FeedMaker.create_pipeline(
        [build_item(source: source, enclosure: enclosure, content_encoded: "<p>Full body</p>")]
      )
      item = rebuilt.items.first

      item.source.url.should == "https://example.com/feed.xml"
      item.enclosure.url.should == "https://example.com/a.mp3"
      item.content_encoded.should == "<p>Full body</p>"
    end

    it "does not fabricate a source, enclosure or content_encoded for an item that had none" do
      rebuilt = Automatic::FeedMaker.create_pipeline([build_item])
      item = rebuilt.items.first

      item.source.should be_nil
      item.enclosure.should be_nil
      item.content_encoded.should be_nil
    end

    it "still preserves the other fields when source is absent" do
      rebuilt = Automatic::FeedMaker.create_pipeline([build_item(source: nil)])
      item = rebuilt.items.first

      item.title.should == "A title"
      item.description.should == "A description"
    end

    it "still preserves the other fields when enclosure is absent" do
      rebuilt = Automatic::FeedMaker.create_pipeline([build_item(enclosure: nil)])
      item = rebuilt.items.first

      item.title.should == "A title"
      item.author.should == "jdoe"
    end

    it "still preserves the other fields when content_encoded is absent" do
      rebuilt = Automatic::FeedMaker.create_pipeline([build_item(content_encoded: nil)])
      item = rebuilt.items.first

      item.title.should == "A title"
      item.comments.should == "https://example.com/a#comments"
    end

    # The bug this fixes: one field the item does not carry used to abort
    # copying every field after it, because they were all attempted inside one
    # begin/rescue NoMethodError block.
    it "does not let a missing author interrupt copying the fields declared after it" do
      rebuilt = Automatic::FeedMaker.create_pipeline(
        [build_item(author: nil, comments: "https://example.com/a#comments",
                     content_encoded: "<p>Full body</p>")]
      )
      item = rebuilt.items.first

      item.author.should be_nil
      item.comments.should == "https://example.com/a#comments"
      item.content_encoded.should == "<p>Full body</p>"
    end

    it "preserves both linked and linkless items" do
      linked = build_item(link: "https://example.com/a", title: "Linked")
      unlinked = build_item(link: nil, title: "Unlinked",
                            description: "A linkless description")

      rebuilt = Automatic::FeedMaker.create_pipeline([linked, unlinked])

      rebuilt.items.size.should == 2
      rebuilt.items.map(&:title).should include("Linked", "Unlinked")

      item = rebuilt.items.find { |candidate| candidate.title == "Unlinked" }
      item.should_not be_nil
      item.link.should be_nil
      item.description.should == "A linkless description"
    end
  end
end
