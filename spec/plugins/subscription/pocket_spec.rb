# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Pocket
# Author::    soramugi <http://soramugi.net>
# Created::   May 21, 2013
# Updated::   Feb 25, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/pocket'

def pocket(config = {}, pipeline = [])
  Automatic::Plugin::SubscriptionPocket.new(config,pipeline)
end

describe 'Automatic::Plugin::SubscriptionPocket' do
  context 'when feed is empty' do
    describe 'attestation error' do
      subject { pocket }

      its(:run) { should be_empty }
    end

    describe 'interval & retry was used error' do
      config = {'interval' => 1, 'retry' => 1}
      subject { pocket(config) }

      its(:run) { should be_empty }
    end
  end

  context 'when feed' do
    describe 'config optional' do
      config = { 'optional' => {
        'count' => 1,
        'favorite' => 1
      }}
      subject { pocket(config) }
      before do
        retrieve = {'list' => {
          'id' => {
          'given_url' => 'http://github.com',
          'given_title' => 'GitHub',
          'excerpt' => 'github'
        }}}
        client = double("client")
        client.should_receive(:retrieve).
          with(config['optional']).
          and_return(retrieve)
        subject.instance_variable_set(:@client, client)
      end

      its(:run) { should have(1).item }
    end
  end
end
