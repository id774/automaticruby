# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Text
# Author::    soramugi <http://soramugi.net>
#             774 <http://id774.net>
# Created::   May  6, 2013
# Updated::   Feb 19, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

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

  context "with urls whose return feed" do
    subject {
      Automatic::Plugin::SubscriptionText.new(
        { 'urls' => ["http://hugehuge"] }
      )
    }

    its(:run) { should have(1).feed }
  end

  context "with feeds whose return feed" do
    subject {
      Automatic::Plugin::SubscriptionText.new(
        { 'feeds' => [ {'title' => 'huge', 'url' => "http://hugehuge"} ] }
      )
    }

    its(:run) { should have(1).feed }
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
