# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::Text
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     May  6, 2013
# Updated::     Sep  7, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/text'

describe Automatic::Plugin::SubscriptionText do
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
end
