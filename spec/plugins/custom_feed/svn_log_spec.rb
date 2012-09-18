# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::CustomFeed::SVNFLog
# Author::    kzgs
# Created::   Feb 29, 2012
# Updated::   Mar  3, 2012
# Copyright:: kzgs Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'custom_feed/svn_log'

describe Automatic::Plugin::CustomFeedSVNLog do
  context "with feeds whose valid URL" do
    subject {
      Automatic::Plugin::CustomFeedSVNLog.new(
        {
          'target' => 'http://redmine.rubyforge.org/svn',
          'fetch_items' => 2
        })
    }

    its(:run) { should have(1).feed }

    specify {
      feed = subject.run[0]
      feed.should have(2).items
    }
  end
end

