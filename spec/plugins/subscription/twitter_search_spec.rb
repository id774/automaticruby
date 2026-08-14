# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::TwitterSearch
# Author: soramugi (More info: http://soramugi.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   May 30, 2013
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# SubscriptionTwitterSearch uses the twitter gem's v4 interface, which no longer
# exists; doc/PLUGINS.md section 6.1 classifies it as Unsupported.
#
# The gem is not a dependency of this project, so this spec is skipped rather
# than stubbed; see doc/POLICY.md section 4.
return unless AutomaticSpec.plugin_available?('subscription/twitter_search')

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
        client = double("client")
        client.should_receive(:search)
        .with(config['search'],config['opt'])
        .and_return(search)
        subject.instance_variable_set(:@client, client)
      end

      its(:run) { should have(1).item }
    end
  end
end
