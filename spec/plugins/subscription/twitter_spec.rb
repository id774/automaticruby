# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Twitter
# Author::    774 <http://id774.net>
# Created::   Sep 10, 2012
# Updated::   Sep 10, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/twitter'

describe Automatic::Plugin::SubscriptionTwitter do
  context "with empty URLs" do
    subject {
      Automatic::Plugin::SubscriptionTwitter.new(
        { 'urls' => [] })
    }
    its(:run) { should be_empty }
  end

  context "with URLs whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionTwitter.new(
        { 'urls' => ["invalid_url"] }
      )
    }
    its(:run) { should be_empty }
  end


  context "with URLs whose valid URL" do
    subject {
      Automatic::Plugin::SubscriptionTwitter.new(
        { 'urls' => [
            "http://id774.net/test/twitter/favorites.html"]
        }
      )
    }

    its(:run) { should have(1).item }
  end
end
