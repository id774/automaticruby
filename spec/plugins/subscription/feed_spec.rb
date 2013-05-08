# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Feed
# Author::    774 <http://id774.net>
# Updated::   Feb  8, 2013
# Copyright:: 774 Copyright (c) 2012-2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/feed'

describe Automatic::Plugin::SubscriptionFeed do
  context "with empty feeds" do
    subject {
      Automatic::Plugin::SubscriptionFeed.new(
        { 'feeds' => [] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with feeds whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionFeed.new(
        { 'feeds' => ["invalid_url"] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with feeds whose valid URL" do
    subject {
      Automatic::Plugin::SubscriptionFeed.new(
        { 'feeds' => [
            "https://github.com/automaticruby/automaticruby/commits/master.atom"]
        }
      )
    }

    its(:run) { should have(1).feed }
  end

  context "with retry to feeds whose valid URL" do
    subject {
      Automatic::Plugin::SubscriptionFeed.new(
        { 'feeds' => [
            "https://github.com/automaticruby/automaticruby/commits/master.atom"],
          'retry' => 3,
          'interval' => 5
        }
      )
    }

    its(:run) { should have(1).feed }
  end

  context "with retry to feeds whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionFeed.new(
        { 'feeds' => ["invalid_url"],
          'retry' => 1,
          'interval' => 1
        }
      )
    }

    its(:run) { should be_empty }
  end
end
