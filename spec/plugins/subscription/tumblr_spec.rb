# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::Tumblr
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Oct 16, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/tumblr'

describe Automatic::Plugin::SubscriptionTumblr do
  context "with empty URLs" do
    subject {
      Automatic::Plugin::SubscriptionTumblr.new(
        { 'urls' => [] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with URLs whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionTumblr.new(
        { 'urls' => ["invalid_url"] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with URLs whose valid URL", :network do
    subject {
      Automatic::Plugin::SubscriptionTumblr.new(
        { 'urls' => [
            "http://reblog.id774.net"]
        }
      )
    }

    its(:run) { should have(1).item }
  end

  context "with URLs and Pages", :network do
    subject {
      Automatic::Plugin::SubscriptionTumblr.new(
        { 'urls' => [
            "http://reblog.id774.net"],
          'pages' => 3,
          'interval' => 5,
          'retry' => 5
        }
      )
    }

    its(:run) { should have(3).item }
  end

  context "with retry to URLs whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionTumblr.new(
        { 'urls' => ["invalid_url"],
          'pages' => 3,
          'interval' => 0,
          'retry' => 2
        }
      )
    }

    its(:run) { should be_empty }
  end
end

# The examples below read a page rather than reach one, so they run without a
# network -- but the reading is FeedParser.parse_html, which needs nokogiri.
# That gem is in the Gemfile's optional :plugins group, which the default
# suite does not install. See doc/POLICY.md section 5.
if AutomaticSpec.optional_dependency?('nokogiri')
describe Automatic::Plugin::SubscriptionTumblr do
  let(:page) {
    '<a href="http://example.tumblr.com/post/1">one</a>' \
    '<a href="https://elsewhere.example/x">two</a>'
  }

  before { Automatic::Http.stub(:read).and_return(page) }

  # A theme's page carries the blog's own posts and a great deal else. A link
  # that leaves the blog's host is blanked rather than removed, which is the
  # pipeline's way of saying "not applicable".
  it "blanks the links that leave the blog's host" do
    plugin = Automatic::Plugin::SubscriptionTumblr.new(
      'urls' => ['http://example.tumblr.com'], 'interval' => 0
    )
    links = plugin.run[0].items.map(&:link)
    links.compact.should == ['http://example.tumblr.com/post/1']
    links.should have(2).links
  end

  it "walks back through the pages the settings ask for" do
    Automatic::Http.should_receive(:read).
      with('http://example.tumblr.com').ordered.and_return(page)
    Automatic::Http.should_receive(:read).
      with('http://example.tumblr.com/page/2').ordered.and_return(page)
    Automatic::Http.should_receive(:read).
      with('http://example.tumblr.com/page/3').ordered.and_return(page)

    Automatic::Plugin::SubscriptionTumblr.new(
      'urls' => ['http://example.tumblr.com'], 'pages' => 3, 'interval' => 0
    ).run.should have(3).feeds
  end

  it "fetches the blog's own page only where no page count is given" do
    Automatic::Http.should_receive(:read).once.and_return(page)
    Automatic::Plugin::SubscriptionTumblr.new(
      'urls' => ['http://example.tumblr.com'], 'interval' => 0
    ).run.should have(1).feed
  end
end
end
