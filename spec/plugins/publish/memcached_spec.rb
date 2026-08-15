# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Memcached
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 25, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# PublishMemcached needs the dalli gem and a memcached server; doc/PLUGINS.md
# section 6.7 classifies it as Supported (external). The gem is an optional
# dependency in its own Gemfile group, so this spec is skipped rather than
# stubbed where it is absent (doc/POLICY.md section 4). Where it is present,
# what is verified is the value the plugin builds and the key it stores it
# under -- no server is contacted.
return unless AutomaticSpec.plugin_available?('publish/memcached')

describe Automatic::Plugin::PublishMemcached do
  let(:cache) { double('cache') }

  let(:pipeline) {
    AutomaticSpec.generate_pipeline {
      feed {
        item 'http://blog.id774.net/post/2012/01/30/18/', 'ブログをはじめた', 'なぜいまブログなのか'
        item 'http://blog.id774.net/post/2012/01/30/38/', 'Twitter Viewer つくった', '本文'
      }
      feed {
        item 'http://d.hatena.ne.jp/Naruhodius/20120130/1327862031', 'ブログを移転しました', '本文'
      }
    }
  }

  subject {
    Automatic::Plugin::PublishMemcached.new(
      { 'host' => 'localhost', 'port' => 11_211, 'key' => 'rspec' }, pipeline
    )
  }

  before { Dalli::Client.stub(:new).and_return(cache) }

  it 'stores the whole pipeline under one key, keyed by link' do
    stored = nil
    cache.should_receive(:set) { |key, value| key.should == 'rspec'; stored = value }
    subject.run.should have(2).feeds

    stored.keys.should have(3).links
    stored['http://blog.id774.net/post/2012/01/30/18/'][:title].should == 'ブログをはじめた'
  end

  # `port: 11211` in a Recipe is an Integer, and building the server address by
  # concatenation used to end the run on it.
  it 'accepts a port written as a number or as a string' do
    Dalli::Client.should_receive(:new).with('localhost:11211').and_return(cache)
    cache.stub(:set)
    subject.run
  end

  it 'logs a failure to store and returns the pipeline' do
    cache.stub(:set).and_raise(RuntimeError, 'connection refused')
    Automatic::Log.stub(:puts)
    Automatic::Log.should_receive(:puts).with('warn', /connection refused/)
    subject.run.should have(2).feeds
  end
end
