# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Link
# Author::    774 <http://id774.net>
# Created::   Sep 18, 2012
# Updated::   Feb  8, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/link'

describe Automatic::Plugin::SubscriptionLink do
  context "with empty URLs" do
    subject {
      Automatic::Plugin::SubscriptionLink.new(
        { 'urls' => [] })
    }

    its(:run) { should be_empty }
  end

  context "with URLs whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionLink.new(
        { 'urls' => ["invalid_url"] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with URLs whose valid URL" do
    subject {
      Automatic::Plugin::SubscriptionLink.new(
        { 'urls' => [
            "http://id774.net"],
          'interval' => 1
        }
      )
    }

    its(:run) { should have(1).item }
  end

  context "with retry to URLs whose valid URL" do
    subject {
      Automatic::Plugin::SubscriptionLink.new(
        { 'urls' => [
            "http://id774.net"],
          'interval' => 2,
          'retry' => 3
        }
      )
    }

    its(:run) { should have(1).item }
  end

  context "with retry to URLs whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionLink.new(
        { 'urls' => ["invalid_url"],
          'interval' => 1,
          'retry' => 1
        }
      )
    }

    its(:run) { should be_empty }
  end
end
