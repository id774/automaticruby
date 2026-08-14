# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::Twitter
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Sep 10, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# SubscriptionTwitter reads HTML with nokogiri, which the Gemfile declares in
# its optional :plugins group. The default suite and CI do not install it, so
# this spec runs only where the operator has. See doc/POLICY.md section 5.
return unless AutomaticSpec.optional_dependency?('nokogiri')

require 'subscription/twitter'

describe Automatic::Plugin::SubscriptionTwitter do
  context "with empty URLs" do
    subject {
      Automatic::Plugin::SubscriptionTwitter.new(
        { 'urls' => [] }
      )
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

  context "with URLs whose valid URL", :network do
    subject {
      Automatic::Plugin::SubscriptionTwitter.new(
        { 'urls' => [
            "http://id774.net/test/twitter/favorites.html"],
          'interval' => 1
        }
      )
    }

    its(:run) { should have(1).item }
  end

  context "with retry to URLs whose valid URL", :network do
    subject {
      Automatic::Plugin::SubscriptionTwitter.new(
        { 'urls' => [
            "http://id774.net/test/twitter/favorites.html"],
          'interval' => 2,
          'retry' => 1
        }
      )
    }

    its(:run) { should have(1).item }
  end

  context "with retry to URLs whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionTwitter.new(
        { 'urls' => ["invalid_url"],
          'interval' => 1,
          'retry' => 2
        }
      )
    }

    its(:run) { should be_empty }
  end
end
