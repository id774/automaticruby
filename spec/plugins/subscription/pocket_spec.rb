# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Pocket
# Author: soramugi (More info: http://soramugi.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   May 21, 2013
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# Pocket was shut down in July 2025;
# doc/PLUGINS.md section 6.1 classifies SubscriptionPocket as Unsupported.
#
# The gem is not a dependency of this project, so this spec is skipped rather
# than stubbed; see doc/POLICY.md section 4.
return unless AutomaticSpec.plugin_available?('subscription/pocket')

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
