# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::ChanToru
# Author: soramugi (More info: http://soramugi.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Jun 28, 2013
# Updated::   Jun 28, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/chan_toru'

def chan_toru(config = {}, pipeline = [])
  Automatic::Plugin::SubscriptionChanToru.new(config,pipeline)
end

describe 'Automatic::Plugin::SubscriptionChanToru' do
  context 'when feed is empty' do
    describe 'attestation error' do
      subject { chan_toru }
      before do
        subject.should_receive(:g_guide_pipeline).times.and_return([])
      end
      its(:run) { should be_empty }
    end

    describe 'interval & retry was used error' do
      config = {'interval' => 1, 'retry' => 1}
      subject { chan_toru(config) }
      before do
        subject.
          should_receive(:g_guide_pipeline).
          exactly(2).
          times.and_return('')
      end
      its(:run) { should be_empty }
    end
  end

  context 'when feed' do
    describe 'config keyword' do
      subject { chan_toru }
      before do
        pipeline = AutomaticSpec.generate_pipeline {
          feed {
          item "http://soramugi.net/images/hugehuge"
          item "http://tv.so-net.ne.jp/schedule/500333201307052330.action?from=rss"
        }}
        subject.
          should_receive(:g_guide_pipeline).
          times.and_return(pipeline)
      end
      its(:run) { should have(1).feed }
    end
  end
end
