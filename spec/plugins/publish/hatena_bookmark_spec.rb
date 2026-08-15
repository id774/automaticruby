# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::HatenaBookmark
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 22, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/hatena_bookmark'

# PublishHatenaBookmark is classified Needs rework in doc/PLUGINS.md section
# 6.7: the service and its bookmarking API are current, the WSSE AtomPub
# interface this speaks is not. Nothing here asserts that a bookmark is made.
# What it holds is the part that a rework will have to keep working anyway --
# how a link is made absolute, what the entry document contains -- and that
# the request goes over TLS, which is the defect that was worth correcting
# before the rest.
describe Automatic::Plugin::PublishHatenaBookmark do
  def plugin_for(link)
    Automatic::Plugin::PublishHatenaBookmark.new(
      { 'username' => 'user', 'password' => 'pswd', 'interval' => 0 },
      AutomaticSpec.generate_pipeline { feed { item link } }
    )
  end

  {
    'http://github.com'  => 'http://github.com',
    'https://github.com' => 'https://github.com',
    '//github.com'       => 'https://github.com',
    'github.com'         => 'https://github.com'
  }.each_pair do |given, expected|
    it "posts #{given.inspect} as #{expected.inspect}" do
      plugin = plugin_for(given)
      hb = double('hb')
      hb.should_receive(:post).with(expected, nil)
      plugin.instance_variable_set(:@hb, hb)
      plugin.run.should have(1).feed
    end
  end
end

describe Automatic::Plugin::HatenaBookmark do
  subject { Automatic::Plugin::HatenaBookmark.new }

  describe '#wsse' do
    it 'builds the header' do
      header = subject.wsse('anonymous', 'pswd')
      header.should be_has_key('X-WSSE')
      header['X-WSSE'].should match(
        /\AUsernameToken Username="anonymous", PasswordDigest=".+", Nonce=".+", Created="\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z"\z/
      )
    end

    it 'uses a different nonce every time' do
      nonce = ->(header) { header['X-WSSE'][/Nonce="([^"]+)"/, 1] }
      nonce.call(subject.wsse('anonymous', 'pswd')).
        should_not == nonce.call(subject.wsse('anonymous', 'pswd'))
    end
  end

  describe '#post' do
    let(:requests) { [] }

    def connection(code)
      response = double('response')
      response.stub(:code).and_return(code)
      double('http').tap { |http|
        http.stub(:request) { |request| requests << request; response }
      }
    end

    it 'posts the entry to the endpoint over TLS' do
      Net::HTTP.should_receive(:Proxy).with(nil, 8080).and_return(
        double('proxy').tap { |proxy|
          proxy.should_receive(:start).
            with('b.hatena.ne.jp', 443, hash_including(use_ssl: true)).
            and_yield(connection('201'))
        }
      )

      subject.post('http://www.google.com', 'Can we trust them ?')

      requests[0].path.should == '/atom/post'
      requests[0]['x-wsse'].should_not be_nil
      requests[0].body.should include('href="http://www.google.com"')
      requests[0].body.should include('Can we trust them ?')
    end

    it 'logs any other response code as an error' do
      Net::HTTP.stub(:Proxy).and_return(
        double('proxy').tap { |proxy| proxy.stub(:start).and_yield(connection('400')) }
      )
      Automatic::Log.stub(:puts)
      Automatic::Log.should_receive(:puts).with(:error, /400 Error/)

      subject.post('http://www.google.com', nil)
    end
  end
end
