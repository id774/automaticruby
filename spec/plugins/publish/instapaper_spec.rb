# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Instapaper
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 9,  2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/instapaper'

# PublishInstapaper needs an Instapaper account; doc/PLUGINS.md section 6.7
# classifies it as Supported (external). Everything up to the request is
# verified here -- what is posted where, with which authentication, and what
# each response code means -- and no example reaches the service. The
# constructor authenticates, so every example stubs the request that does it.
describe Automatic::Plugin::PublishInstapaper do
  let(:settings) {
    { 'email' => 'email@example.com', 'password' => 'pswd',
      'interval' => 0, 'retry' => 1 }
  }

  before { Automatic::Plugin::Instapaper.any_instance.stub(:request) }

  subject {
    Automatic::Plugin::PublishInstapaper.new(
      settings,
      AutomaticSpec.generate_pipeline { feed { item 'http://github.com' } }
    )
  }

  it 'adds the link in the feed and returns the pipeline' do
    instapaper = double('instapaper')
    instapaper.should_receive(:add).with('http://github.com', nil, '')
    subject.instance_variable_set(:@instapaper, instapaper)
    subject.run.should have(1).feed
  end

  it 'retries a failing item and carries on' do
    instapaper = double('instapaper')
    instapaper.should_receive(:add).twice.and_raise(
      Automatic::Plugin::Instapaper::Error, 'Instapaper answered 403'
    )
    subject.instance_variable_set(:@instapaper, instapaper)
    subject.run.should have(1).feed
  end
end

describe Automatic::Plugin::Instapaper do
  before { Automatic::Plugin::Instapaper.any_instance.stub(:request) }

  subject { Automatic::Plugin::Instapaper.new('email@example.com', 'pswd') }

  describe '#add' do
    it 'returns the response when the service accepts the URL' do
      response = double('response', code: '201')
      subject.should_receive(:request).
        with(:add, url: 'http://www.google.com', title: 'a title', selection: 'a body').
        and_return(response)
      subject.add('http://www.google.com', 'a title', 'a body').should == response
    end

    it 'raises on any other response code' do
      subject.stub(:request).and_return(double('response', code: '403'))
      lambda {
        subject.add('http://www.google.com', 'a title', 'a body')
      }.should raise_error(Automatic::Plugin::Instapaper::Error, /403/)
    end
  end

  describe 'the request it builds' do
    # Unstubbed here, because the request itself is what is being checked;
    # Net::HTTP.start is stubbed, so nothing is sent.
    before { Automatic::Plugin::Instapaper.any_instance.unstub(:request) }

    it 'posts the form to the Simple API over TLS, with the certificate verified' do
      posted = nil
      Net::HTTP.should_receive(:start).
        with('www.instapaper.com', 443,
             hash_including(use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_PEER)) { |*_args, &block|
          http = double('http')
          http.stub(:request) { |request| posted = request; double('response', code: '201') }
          block.call(http)
        }.at_least(:once)

      Automatic::Plugin::Instapaper.new('email@example.com', 'pswd')

      posted.path.should == '/api/authenticate'
      posted['authorization'].should == "Basic #{['email@example.com:pswd'].pack('m0')}"
    end
  end
end
