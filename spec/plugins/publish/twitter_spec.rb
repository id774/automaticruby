# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Twitter
# Author::    soramugi <http://soramugi.net>
# Created::   May  5, 2013
# Updated::   May  5, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/twitter'

describe Automatic::Plugin::PublishTwitter do
  subject {
    Automatic::Plugin::PublishTwitter.new(
      { 'consumer_key'       => 'your_consumer_key',
        'consumer_secret'    => 'your_consumer_secret',
        'oauth_token'        => 'your_oauth_token',
        'oauth_token_secret' => 'your_oauth_token_secret',
        'interval'           => 5,
        'retry'              => 5
      },
      AutomaticSpec.generate_pipeline{
        feed { item "http://github.com" }
      }
    )
  }

  it "should post the link tweet" do
    twitter = mock("twitter")
    twitter.should_receive(:update).with(" http://github.com")
    subject.instance_variable_set(:@twitter, twitter)
    subject.run.should have(1).feed
  end
end
