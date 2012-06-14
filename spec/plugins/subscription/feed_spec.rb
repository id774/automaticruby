# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Feed
# Author::    774 <http://id774.net>
# Updated::   Jun 14, 2012
# Copyright:: 774 Copyright (c) 2012
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
            "https://github.com/id774/automaticruby/commits/master.atom"]
        }
      )
    }

    its(:run) { should have(1).feed }
  end
end
