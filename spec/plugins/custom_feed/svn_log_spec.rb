# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::CustomFeed::SVNLog
# Author:       kzgs
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 29, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'custom_feed/svn_log'

# CustomFeedSVNLog needs the svn command, which is the operator's to install
# and which doc/PLUGINS.md section 6.2 classifies it as Supported (external)
# for. What is verified here is everything on this side of that command: the
# document it prints becomes a feed, and the arguments it is given are the
# ones the plugin's settings ask for. Running the command itself is the
# :network example at the end, which is excluded from the default suite.
describe Automatic::Plugin::CustomFeedSVNLog do
  SVN_LOG_XML = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <log>
      <logentry revision="1913406">
        <author>someone</author>
        <date>2026-08-01T09:15:22.123456Z</date>
        <msg>Fix the thing</msg>
      </logentry>
      <logentry revision="1913405">
        <author>another</author>
        <date>2026-07-30T22:04:11.000000Z</date>
        <msg>Add the other thing</msg>
      </logentry>
    </log>
  XML

  subject {
    Automatic::Plugin::CustomFeedSVNLog.new(
      'target' => 'https://svn.example.com/repos/project/',
      'fetch_items' => 2,
      'title' => 'project'
    )
  }

  before { subject.stub(:svn_log).and_return(SVN_LOG_XML) }

  its(:run) { should have(1).feed }

  it 'makes one item per revision' do
    subject.run[0].items.should have(2).items
  end

  it 'titles an item with its message and author' do
    subject.run[0].items[0].title.should == 'Fix the thing by someone'
  end

  it 'links an item to its revision, with the trailing slash of target removed' do
    subject.run[0].items[0].link.
      should == 'https://svn.example.com/repos/project/!svn/bc/1913406'
  end

  it 'takes the revision date' do
    subject.run[0].items[0].date.should == Time.parse('2026-08-01T09:15:22.123456Z')
  end

  it 'takes the channel title from the settings' do
    subject.run[0].channel.title.should == 'project'
  end

  context 'with no revisions' do
    before { subject.stub(:svn_log).and_return("<?xml version=\"1.0\"?>\n<log>\n</log>\n") }

    it 'returns the pipeline unchanged' do
      subject.run.should be_empty
    end
  end

  describe 'the command' do
    # An argument vector rather than a command line: a repository URL is an
    # argument to svn and cannot become part of a shell command.
    it 'passes the repository, --xml and the limit to svn' do
      plugin = Automatic::Plugin::CustomFeedSVNLog.new(
        'target' => 'https://svn.example.com/repos/project', 'fetch_items' => 5
      )
      IO.should_receive(:popen).
        with(['svn', 'log', 'https://svn.example.com/repos/project',
              '--xml', '--limit=5'], err: File::NULL).
        and_return(SVN_LOG_XML)
      plugin.stub(:raise)
      plugin.send(:revisions)
    end

    it 'defaults the limit to 30' do
      plugin = Automatic::Plugin::CustomFeedSVNLog.new(
        'target' => 'https://svn.example.com/repos/project'
      )
      plugin.send(:limit).should == 30
    end
  end

  context 'against a real repository', :network do
    subject {
      Automatic::Plugin::CustomFeedSVNLog.new(
        'target' => 'https://svn.apache.org/repos/asf/', 'fetch_items' => 2
      )
    }

    its(:run) { should have(1).feed }
  end
end
