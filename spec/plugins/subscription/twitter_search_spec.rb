# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::TwitterSearch
# Author::    soramugi <http://soramugi.net>
# Created::   May 30, 2013
# Updated::   May 30, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/twitter_search'

def twitter_search(config = {}, pipeline = [])
  Automatic::Plugin::SubscriptionTwitterSearch.new(config,pipeline)
end

describe 'Automatic::Plugin::SubscriptionTwitterSearch' do
  context 'when feed is empty' do

    describe 'attestation error' do
      subject { twitter_search }

      its(:run) { should be_empty }
    end

    describe 'interval & retry was used error' do
      config = {'interval' => 1, 'retry' => 1}
      subject { twitter_search(config) }

      its(:run) { should be_empty }
    end

  end

  context 'when feed' do
    describe 'config optional' do
      config = { 'search' => 'ruby', 'opt' => { 'lang' => 'ja', 'count' => 1 }}
      subject { twitter_search(config) }
      before do
        status            = Hashie::Mash.new
        status.user       = {'screen_name' => 'soramugi'}
        status.id         = 12345
        status.text       = 'twitter_search rspec'
        status.created_at = Time.now
        search         = Hashie::Mash.new
        search.results = [status]
        client = mock("client")
        client.should_receive(:search)
        .with(config['search'],config['opt'])
        .and_return(search)
        subject.instance_variable_set(:@client, client)
      end

      its(:run) { should have(1).item }
    end
  end
end
