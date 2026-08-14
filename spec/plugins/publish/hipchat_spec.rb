# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Hipchat
# Author:       Kohei Hasegawa (More info: http://github.com/banyan)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 5,  2013
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')
# HipChat was shut down by Atlassian;
# doc/PLUGINS.md section 6.7 classifies PublishHipchat as Unsupported.
#
# The gem is not a dependency of this project, so this spec is skipped rather
# than stubbed; see doc/POLICY.md section 4.
return unless AutomaticSpec.plugin_available?('publish/hipchat')

describe Automatic::Plugin::PublishHipchat do
  let(:config) {
    {
      'api_token' => "bogus_api_token",
      'room_id'   => 'bogus_room',
      'username'  => 'bogus_bot',
      'interval'  => 1,
      'retry'     => 1
    }
  }

  let(:pipeline) {
    AutomaticSpec.generate_pipeline {
      feed { item("http://github.com", 'title', 'description') }
    }
  }

  context 'return feed' do
    subject {
      described_class.new(config, pipeline)
    }

    context 'when successfully' do
      it "should passed proper argument to HipChat::Client" do
        client = double('client').as_null_object
        HipChat::Client.should_receive(:new).with("bogus_api_token").and_return(client)
        subject.run
      end

      it "should post the link in the feed" do
        client = double("client")
        client.should_receive(:send).with('bogus_bot', 'description', {"color"=>"yellow", "notify"=>false})
        subject.instance_variable_set(:@client, client)
        subject.run.should have(1).feed
      end
    end

    context 'when raise an error during post' do
      it do
        client = double("client")
        client.stub(:send).and_raise
        subject.instance_variable_set(:@client, client)
        Automatic::Log.should_receive(:puts).twice
        subject.run.should have(1).feed
      end
    end
  end

  context 'when feed is empty' do
    subject {
      described_class.new(config)
    }

    it "should not post" do
      subject.run.should have(0).feed
    end
  end
end
