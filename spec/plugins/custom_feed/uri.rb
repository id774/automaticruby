# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::CustomFeed::URI
# Author::    774 <http://id774.net>
# Created::   Jun 12, 2012
# Updated::   Jun 12, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'custom_feed/uri'

describe Automatic::Plugin::CustomFeedURI do
  context "with empty URLs" do
    subject {
      Automatic::Plugin::CustomFeedURI.new(
        { 'urls' => [] })
    }
    its(:run) { should be_empty }
  end

  context "with URLs whose invalid URL" do
    subject {
      Automatic::Plugin::CustomFeedURI.new(
        { 'urls' => ["invalid_url"] }
      )
    }
    its(:run) { should be_empty }
  end


  context "with URLs whose valid URL" do
    subject {
      Automatic::Plugin::CustomFeedURI.new(
        { 'urls' => [
            "https://github.com/id774/automaticruby"]
        }
      )
    }

    its(:run) { should have(1).feed }
  end
end
