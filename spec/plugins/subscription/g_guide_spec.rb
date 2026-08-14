# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::GGuide
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Jun 28, 2013
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/g_guide'

def g_guide(config = {}, pipeline = [])
  Automatic::Plugin::SubscriptionGGuide.new(config,pipeline)
end

describe 'Automatic::Plugin::SubscriptionGGuide' do
  context 'when config' do
    describe 'is empty' do
      subject { g_guide }

      its(:feed_url) {
        should == Automatic::Plugin::SubscriptionGGuide::G_GUIDE_RSS +
        'stationPlatformId=0&'
      }
    end
    describe 'keyword is anime' do
      config = { 'keyword' => 'anime' }
      subject { g_guide(config) }

      it 'feed_url' do
        subject.feed_url(config['keyword']).should == URI::Parser.new.escape(
          Automatic::Plugin::SubscriptionGGuide::G_GUIDE_RSS +
            "condition.keyword=#{config['keyword']}&" +
            'stationPlatformId=0&')
      end
    end
    describe 'station is 地上波' do
      config = { 'station' => '地上波' }
      subject { g_guide(config) }

      its(:feed_url) {
        should == URI::Parser.new.escape(
          Automatic::Plugin::SubscriptionGGuide::G_GUIDE_RSS +
            'stationPlatformId=1&')
      }
    end
  end

  context 'when feed is empty' do
    describe 'attestation error' do
      subject { g_guide }
      before do
        subject.should_receive(:feed_url).and_return('')
      end
      its(:run) { should be_empty }
    end

    describe 'interval & retry was used error' do
      config = {'interval' => 1, 'retry' => 1}
      subject { g_guide(config) }
      before do
        subject.should_receive(:feed_url).exactly(2).times.and_return('')
      end
      its(:run) { should be_empty }
    end
  end

  context 'when feed', :network do
    describe 'config keyword' do
      config = { 'keyword' => 'アニメ', 'station' => '地上波' }
      subject { g_guide(config) }
      its(:run) { should have(1).feed }
    end

    describe 'config keyword ","' do
      config = { 'keyword' => 'おじゃる丸,忍たま', 'station' => '地上波' }
      subject { g_guide(config) }
      its(:run) { should have(2).feed }
    end
  end
end
