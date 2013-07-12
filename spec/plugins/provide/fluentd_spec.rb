# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Provide::Fluentd
# Author::    774 <http://id774.net>
# Created::   Jul 12, 2013
# Updated::   Jul 12, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'provide/fluentd'

describe Automatic::Plugin::ProvideFluentd do
  context 'when feed' do
    describe 'should forward the feeds' do
      feeds = []
      hash = {}
      hash['test1'] = "test2"
      hash['test3'] = "test4"
      expect = hash
      json = hash.to_json
      data = ActiveSupport::JSON.decode(json)
      url = "http://id774.net"
      rss = Automatic::FeedParser.content_provide(url, data)
      feeds << rss

      subject {
        Automatic::Plugin::ProvideFluentd.new(
          {
            'host' => "localhost",
            'port' => "10000",
            'tag'  => "automatic_test.provide_fluentd_spec"
          },
          feeds
        )
      }

      its (:run) {
        fluentd = mock("fluentd")
        subject.run.should have(1).feed
        subject.instance_variable_get(:@pipeline)[0].items[0].content_encoded.should == expect
      }
    end

  end
end
