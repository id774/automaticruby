# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::GoogleReaderStar
# Author::    soramugi <http://soramugi.net>
#             774 <http://id774.net>
# Created::   Feb 10, 2013
# Updated::   Feb 17, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/google_reader_star'

describe Automatic::Plugin::SubscriptionGoogleReaderStar do
  context "with empty feeds" do
    subject {
      Automatic::Plugin::SubscriptionGoogleReaderStar.new(
        { 'feeds' => [] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with feeds whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionGoogleReaderStar.new(
        { 'feeds' => ["invalid_url"] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with feeds whose valid URL" do
    subject {
      Automatic::Plugin::SubscriptionGoogleReaderStar.new(
        { 'feeds' => [
            "http://www.google.com/reader/public/atom/user%2F00482198897189159802%2Fstate%2Fcom.google%2Fstarred"]
        }
      )
    }

    its(:run) { should have(1).feed }
  end

  context "with retry to feeds whose valid URL" do
    subject {
      Automatic::Plugin::SubscriptionGoogleReaderStar.new(
        { 'feeds' => [
            "http://www.google.com/reader/public/atom/user%2F00482198897189159802%2Fstate%2Fcom.google%2Fstarred"],
          'retry' => 3,
          'interval' => 5
        }
      )
    }

    its(:run) { should have(1).feed }
  end

  context "with retry to feeds whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionGoogleReaderStar.new(
        { 'feeds' => ["invalid_url"],
          'retry' => 1,
          'interval' => 1
        }
      )
    }

    its(:run) { should be_empty }
  end

end
