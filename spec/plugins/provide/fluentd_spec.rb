# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Provide::Fluentd
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jul 12, 2013
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# ProvideFluentd needs the optional fluent-logger gem;
# doc/PLUGINS.md section 6.5 classifies it as Supported (external).
#
# The gem is not a dependency of this project, so this spec is skipped rather
# than stubbed; see doc/POLICY.md section 4.
return unless AutomaticSpec.plugin_available?('provide/fluentd')

describe Automatic::Plugin::ProvideFluentd do
  context 'when feed' do
    describe 'should forward the feeds' do
      hash = {}
      hash['test1'] = "test2"
      hash['test3'] = "test4"
      expect = hash

      feeds = []
      json = hash.to_json
      data = ActiveSupport::JSON.decode(json)
      url = "http://id774.net/test/xml/data"
      rss = Automatic::FeedMaker.content_provide(url, data)
      feeds << rss

      subject {
        Automatic::Plugin::ProvideFluentd.new(
          {
            'host' => "localhost",
            'port' => "10000",
            'tag'  => "automatic_spec.provide_fluentd",
            'mode' => "test"
          },
          feeds
        )
      }

      its (:run) {
        fluentd = double("fluentd")
        subject.run.should have(1).feed
        subject.instance_variable_get(:@pipeline)[0].items[0].content_encoded.class == Hash
        subject.instance_variable_get(:@pipeline)[0].items[0].content_encoded.should == expect
      }
    end

  end
end
