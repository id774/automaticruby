# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Twitter
# Author::    soramugi <http://soramugi.net>
# Created::   May  5, 2013
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# PublishTwitter uses the twitter gem's v4 interface, which no longer exists;
# doc/PLUGINS.md section 6.7 classifies it as Unsupported.
#
# The gem is not a dependency of this project, so this spec is skipped rather
# than stubbed; see doc/POLICY.md section 4.
return unless AutomaticSpec.plugin_available?('publish/twitter')

describe Automatic::Plugin::PublishTwitter do
  context 'when feed' do
    describe 'should post the link tweet' do
      subject {
        Automatic::Plugin::PublishTwitter.new(
          {},
          AutomaticSpec.generate_pipeline{
        feed { item "http://github.com" }
      })}

      its (:run) {
        twitter = double("twitter")
        twitter.should_receive(:update).with(" http://github.com")
        subject.instance_variable_set(:@twitter, twitter)
        subject.run.should have(1).feed
      }
    end

    describe 'should post the tweet_tmp' do
      subject {
        Automatic::Plugin::PublishTwitter.new(
          { 'tweet_tmp' => 'publish-twitter'},
          AutomaticSpec.generate_pipeline{
        feed { item "http://github.com" }
      })}

      its (:run) {
        twitter = double("twitter")
        twitter.should_receive(:update).with("publish-twitter")
        subject.instance_variable_set(:@twitter, twitter)
        subject.run.should have(1).feed
      }
    end

    describe 'interval & retry was used error' do
      subject {
        Automatic::Plugin::PublishTwitter.new(
          { 'interval' => 1, 'retry' => 1 },
          AutomaticSpec.generate_pipeline{
        feed { item "http://github.com" }
      })}

      its (:run) {
        subject.run.should have(1).feed
      }
    end
  end

  context 'when feed is empty' do
    describe 'should not post' do
      subject {
        Automatic::Plugin::PublishTwitter.new(
          {},
      )}

      its (:run) {
        subject.run.should have(0).feed
      }
    end
  end
end
