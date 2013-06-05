# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Hipchat
# Author::    Kohei Hasegawa <http://github.com/banyan>
# Created::   Jun 5, 2013
# Updated::   Jun 5, 2013
# Copyright:: Kohei Hasegawa Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')
require 'publish/hipchat'

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

    it "should passed proper argument to HipChat::Client" do
      client = mock('client').as_null_object
      HipChat::Client.should_receive(:new).with("bogus_api_token").and_return(client)
      subject.run
    end

    it "should post the link in the feed" do
      client = mock("client")
      client.should_receive(:send).with('bogus_bot', 'description', {"color"=>"yellow", "notify"=>false})
      subject.instance_variable_set(:@client, client)
      subject.run.should have(1).feed
    end

    it "should raise an error during post" do
      client = mock("client")
      client.stub(:send).and_raise
      subject.instance_variable_set(:@client, client)
      Automatic::Log.should_receive(:puts).twice
      subject.run.should have(1).feed
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
