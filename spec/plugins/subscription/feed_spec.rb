# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Feed
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

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
          'interval' => 1
        }
      )
    }

    its(:run) { should be_empty }
  end
end
