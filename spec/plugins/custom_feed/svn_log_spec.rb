# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::CustomFeed::SVNFLog
# Author: kzgs
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Feb 29, 2012
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# CustomFeedSVNLog needs the optional xml-simple gem and the svn command;
# doc/PLUGINS.md section 6.2 classifies it as Supported (external).
#
# The gem is not a dependency of this project, so this spec is skipped rather
# than stubbed; see doc/POLICY.md section 4.
return unless AutomaticSpec.plugin_available?('custom_feed/svn_log')

describe Automatic::Plugin::CustomFeedSVNLog do
  context "with feeds whose valid URL" do
    subject {
      Automatic::Plugin::CustomFeedSVNLog.new(
        {
          'target' => 'http://svn.apache.org/repos/asf/',
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

