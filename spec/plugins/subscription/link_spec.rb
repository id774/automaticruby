# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Link
# Author::    774 <http://id774.net>
# Created::   Sep 18, 2012
# Updated::   Sep 18, 2012
# Copyright:: 774 Copyright (c) 2012
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
            "http://id774.net"]
        }
      )
    }

    its(:run) { should have(1).item }
  end
end
