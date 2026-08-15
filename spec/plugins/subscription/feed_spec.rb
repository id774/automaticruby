# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::Feed
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 25, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

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

  context "with feeds whose valid URL", :network do
    subject {
      Automatic::Plugin::SubscriptionFeed.new(
        { 'feeds' => [
            "https://github.com/id774/automaticruby/commits/master.atom"]
        }
      )
    }

    its(:run) { should have(1).feed }
  end

  context "with retry to feeds whose valid URL", :network do
    subject {
      Automatic::Plugin::SubscriptionFeed.new(
        { 'feeds' => [
            "https://github.com/id774/automaticruby/commits/master.atom"],
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
          'interval' => 0
        }
      )
    }

    its(:run) { should be_empty }
  end

  # `interval` is seconds between attempts, and it was not being waited: the
  # line meant to do it assigned to a local variable named sleep and returned
  # at once, so a Recipe asking to be gentle with a host was not.
  context "with an interval between attempts" do
    subject {
      Automatic::Plugin::SubscriptionFeed.new(
        { 'feeds' => ["invalid_url"], 'retry' => 2, 'interval' => 7 }
      )
    }

    it "waits between them" do
      subject.should_receive(:sleep).with(7).twice
      subject.run.should be_empty
    end
  end

  context "with no feeds at all" do
    subject { Automatic::Plugin::SubscriptionFeed.new(nil) }

    its(:run) { should be_empty }
  end
end
