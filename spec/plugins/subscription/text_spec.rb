# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::Text
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     May  6, 2013
# Updated::     Sep  8, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/text'

describe Automatic::Plugin::SubscriptionText do
  def items_from_tsv(contents)
    Dir.mktmpdir('automatic-subscription-text') do |dir|
      path = File.join(dir, 'input.tsv')
      File.write(path, contents, encoding: 'UTF-8')
      Automatic::Plugin::SubscriptionText.new(
        { 'files' => [path] }
      ).run.flat_map(&:items)
    end
  end

  context "with empty titles" do
    subject {
      Automatic::Plugin::SubscriptionText.new(
        { 'titles' => [] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with titles whose return feed" do
    subject {
      Automatic::Plugin::SubscriptionText.new(
        { 'titles' => ["hugehuge"] }
      )
    }

    its(:run) { should have(1).feed }
  end

  it "builds a title-only item with no placeholder link" do
    returned = Automatic::Plugin::SubscriptionText.new(
      { "titles" => ["hugehuge"] }
    ).run
    item = returned.first.items.first

    item.title.should == "hugehuge"
    item.link.should be_nil
  end

  context "with urls whose return feed" do
    subject {
      Automatic::Plugin::SubscriptionText.new(
        { 'urls' => ["http://hugehuge"] }
      )
    }

    its(:run) { should have(1).feed }
  end

  it "builds a URL-only item with no placeholder title" do
    returned = Automatic::Plugin::SubscriptionText.new(
      { "urls" => ["http://hugehuge"] }
    ).run
    item = returned.first.items.first

    item.title.should be_nil
    item.link.should == "http://hugehuge"
  end

  context "with feeds whose return feed" do
    subject {
      Automatic::Plugin::SubscriptionText.new(
        { 'feeds' => [ {'title' => 'huge', 'url' => "http://hugehuge"} ] }
      )
    }

    its(:run) { should have(1).feed }
  end

  it "keeps an explicitly supplied title and URL" do
    returned = Automatic::Plugin::SubscriptionText.new(
      { "feeds" => [{ "title" => "huge", "url" => "http://hugehuge" }] }
    ).run
    item = returned.first.items.first

    item.title.should == "huge"
    item.link.should == "http://hugehuge"
  end

  context "with feeds including full fields whose return feed" do
    subject {
      Automatic::Plugin::SubscriptionText.new(
        { 'feeds' => [ {'title' => 'huge', 'url' => "http://hugehuge", 'description' => "aaa", 'comments' => "bbb", 'author' => "ccc" } ] }
      )
    }

    its(:run) { should have(1).feed }
  end

  context "with file whose return feed" do
    subject {
      Automatic::Plugin::SubscriptionText.new(
        { 'files' => ["spec/fixtures/sampleFeeds.tsv"] }
      )
    }

    its(:run) { should have(1).feed }
  end

  context "with files whose return feed" do
    subject {
      Automatic::Plugin::SubscriptionText.new(
        { 'files' => ["spec/fixtures/sampleFeeds.tsv", "spec/fixtures/sampleFeeds2.tsv"] }
      )
    }

    its(:run) { should have(1).feed }
  end

  it "builds a title-only item from a one-column TSV row" do
    items = items_from_tsv("Title only\n")

    items.should have(1).item
    items.first.title.should == "Title only"
    items.first.link.should be_nil
  end

  it "preserves a leading empty title column in a URL-only TSV row" do
    items = items_from_tsv("\thttps://example.com/\r\n")

    items.should have(1).item
    items.first.title.should be_nil
    items.first.link.should == "https://example.com/"
  end

  it "does not shift comments across an empty author column" do
    items = items_from_tsv(
      "Title\thttps://example.com/\tDescription\t\tComment\n"
    )
    item = items.first

    items.should have(1).item
    item.title.should == "Title"
    item.link.should == "https://example.com/"
    item.description.should == "Description"
    item.author.should == ""
    item.comments.should == "Comment"
  end

  it "accepts trailing empty TSV fields without changing earlier columns" do
    items = items_from_tsv(
      "Title\thttps://example.com/\tDescription\t\t\n"
    )
    item = items.first

    items.should have(1).item
    item.title.should == "Title"
    item.link.should == "https://example.com/"
    item.description.should == "Description"
    item.author.should == ""
    item.comments.should == ""
  end

  it "ignores blank and all-empty TSV rows" do
    items = items_from_tsv(
      "\n\t\t\t\t\nKept\thttps://example.com/\n"
    )

    items.should have(1).item
    items.first.title.should == "Kept"
    items.first.link.should == "https://example.com/"
  end

  it "ignores TSV columns after comments" do
    items = items_from_tsv(
      "Title\thttps://example.com/\tDescription\tAuthor\tComment\tExtra\tMore\n"
    )
    item = items.first

    items.should have(1).item
    item.title.should == "Title"
    item.link.should == "https://example.com/"
    item.description.should == "Description"
    item.author.should == "Author"
    item.comments.should == "Comment"
  end

  it "preserves field whitespace other than the line ending" do
    items = items_from_tsv(
      "  Title  \thttps://example.com/\t  Description  \n"
    )
    item = items.first

    item.title.should == "  Title  "
    item.description.should == "  Description  "
  end
end
