# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Notify::Ikachan
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar  9, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'notify/ikachan'

# NotifyIkachan needs an ikachan gateway, which is software the operator runs;
# doc/PLUGINS.md section 6.6 classifies it as Supported (external). What is
# verified here is the request the plugin builds, and no example reaches a
# gateway.
describe Automatic::Plugin::NotifyIkachan do
  settings = {
    'channels' => 'room,#other',
    'url'      => 'http://sample.com',
    'port'     => '4979',
    'command'  => 'notice',
    'interval' => 0
  }

  subject {
    Automatic::Plugin::NotifyIkachan.new(
      settings,
      AutomaticSpec.generate_pipeline {
        feed { item "http://github.com", "GitHub" }
      }
    )
  }

  it "posts the title and the link of each item, and returns the pipeline" do
    ikachan = double("ikachan")
    ikachan.should_receive(:post).with("http://github.com", "GitHub")
    subject.instance_variable_set(:@ikachan, ikachan)
    subject.run.should have(1).feed
  end

  it "adds a leading # to a channel that has none, and keeps one that has" do
    subject.ikachan.params['channels'].should == ['#room', '#other']
  end
end

describe Automatic::Plugin::Ikachan do
  subject {
    Automatic::Plugin::Ikachan.new.tap { |ikachan|
      ikachan.params = {
        'channels' => ['#room'],
        'url'      => 'http://sample.com',
        'port'     => '4979',
        'command'  => 'notice'
      }
    }
  }

  describe "#post" do
    let(:requests) { [] }
    let(:http) {
      response = double("response")
      response.stub(:code).and_return("200")
      double("http").tap { |connection|
        connection.stub(:request) { |request| requests << request; response }
      }
    }

    before do
      Net::HTTP.stub(:Proxy).and_return(
        double("proxy").tap { |proxy| proxy.stub(:start).and_yield(http) }
      )
    end

    it "joins the channel and then posts the message, form encoded" do
      subject.post("http://www.google.com")

      requests.map(&:path).should == ['/join', '/notice']
      requests[0].body.should == 'channel=%23room'
      requests[1].body.should == 'channel=%23room&message=http%3A%2F%2Fwww.google.com'
    end

    # An ampersand in a title used to split the request in two and lose the
    # rest of the message.
    it "encodes a title carrying a separator" do
      subject.post("http://www.google.com", "Tom & Jerry")

      URI.decode_www_form(requests[1].body).to_h['message'].
        should == 'Tom & Jerry - http://www.google.com'
    end

    it "connects to the host and port the settings name" do
      Net::HTTP.should_receive(:Proxy).with(nil, 8080).and_return(
        double("proxy").tap { |proxy|
          proxy.should_receive(:start).
            with('sample.com', 4979, hash_including(use_ssl: false)).and_yield(http)
        }
      )
      subject.post("http://www.google.com")
    end

    it "uses TLS where the gateway URL does" do
      subject.params['url'] = 'https://sample.com'
      Net::HTTP.should_receive(:Proxy).and_return(
        double("proxy").tap { |proxy|
          proxy.should_receive(:start).
            with('sample.com', 4979, hash_including(use_ssl: true)).and_yield(http)
        }
      )
      subject.post("http://www.google.com")
    end
  end
end
