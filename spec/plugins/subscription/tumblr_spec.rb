# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Tumblr
# Author::    774 <http://id774.net>
# Created::   Oct 16, 2012
# Updated::   Dec 20, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/tumblr'

describe Automatic::Plugin::SubscriptionTumblr do
  context "with empty URLs" do
    subject {
      Automatic::Plugin::SubscriptionTumblr.new(
        { 'urls' => [] })
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

  context "with URLs whose valid URL" do
    subject {
      Automatic::Plugin::SubscriptionTumblr.new(
        { 'urls' => [
            "http://reblog.id774.net"]
        }
      )
    }

    its(:run) { should have(1).item }
  end

  context "with URLs and Pages" do
    subject {
      Automatic::Plugin::SubscriptionTumblr.new(
        { 'urls' => [
            "http://reblog.id774.net"],
          'pages' => 3
        }
      )
    }

    its(:run) { should have(3).item }
  end
end
