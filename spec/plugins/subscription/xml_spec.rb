# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Xml
# Author::    774 <http://id774.net>
# Created::   Jul 12, 2013
# Updated::   Jul 12, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/xml'

describe Automatic::Plugin::SubscriptionXml do
  context "with empty URLs" do
    subject {
      Automatic::Plugin::SubscriptionXml.new(
        { 'urls' => [] })
    }

    its(:run) { should be_empty }
  end

  context "with URLs whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionXml.new(
        { 'urls' => ["invalid_url"] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with URLs whose invalid Xml" do
    subject {
      Automatic::Plugin::SubscriptionXml.new(
        { 'urls' => [
            "http://id774.net"]
        }
      )
    }

    its(:run) { should be_empty }
  end

  context "with URLs whose valid XML" do
    subject {
      Automatic::Plugin::SubscriptionXml.new(
        { 'urls' => [
            "http://id774.net/test/xml/data"],
          'interval' => 1
        }
      )
    }

    its(:run) { should have(1).item }
  end

  context "with retry to URLs whose valid XML" do
    subject {
      Automatic::Plugin::SubscriptionXml.new(
        { 'urls' => [
            "http://id774.net/test/xml/data"],
          'interval' => 2,
          'retry' => 3
        }
      )
    }

    its(:run) { should have(1).item }
  end

  context "with retry to URLs whose invalid XML" do
    subject {
      Automatic::Plugin::SubscriptionXml.new(
        { 'urls' => ["invalid_url"],
          'interval' => 1,
          'retry' => 1
        }
      )
    }

    its(:run) { should be_empty }
  end
end
