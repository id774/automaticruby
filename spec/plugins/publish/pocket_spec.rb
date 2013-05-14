# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Pocket
# Author::    soramugi <http://soramugi.net>
# Created::   May 15, 2013
# Updated::   May 15, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/pocket'

describe Automatic::Plugin::PublishPocket do
  subject {
    Automatic::Plugin::PublishPocket.new(
      { 'consumer_key' => "hugehuge",
        'access_token' => "hogehoge",
        'interval' => 1,
        'retry' => 1
      },
      AutomaticSpec.generate_pipeline{
        feed { item "http://github.com" }
      }
    )
  }

  it "should post the link in the feed" do
    client = mock("client")
    client.should_receive(:add).with(:url => 'http://github.com')
    subject.instance_variable_set(:@client, client)
    subject.run.should have(1).feed
  end
end

describe Automatic::Plugin::PublishPocket do
  subject {
    Automatic::Plugin::PublishPocket.new(
      { 'consumer_key' => "hugehuge",
        'access_token' => "hogehoge",
        'interval' => 1,
        'retry' => 1
      },
      AutomaticSpec.generate_pipeline{
      }
    )
  }

  it "should un post" do
    subject.run.should have(0).feed
  end
end
