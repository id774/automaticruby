# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Fluentd
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 21, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# PublishFluentd needs the fluent-logger gem and a Fluentd instance;
# doc/PLUGINS.md section 6.7 classifies it as Supported (external). The gem is
# an optional dependency in its own Gemfile group, so this spec is skipped
# rather than stubbed where it is absent. See doc/POLICY.md section 4.
return unless AutomaticSpec.plugin_available?('publish/fluentd')

describe Automatic::Plugin::PublishFluentd do
  let(:settings) {
    { 'host' => 'localhost', 'port' => '10000', 'tag' => 'automatic_spec.publish_fluent' }
  }

  let(:pipeline) {
    AutomaticSpec.generate_pipeline {
      feed { item 'http://github.com', 'hoge', '<a>fuga</a>' }
    }
  }

  context 'in test mode' do
    subject { Automatic::Plugin::PublishFluentd.new(settings.merge('mode' => 'test'), pipeline) }

    it 'builds no connection and returns the pipeline unchanged' do
      Fluent::Logger::FluentLogger.should_not_receive(:open)
      subject.run.should have(1).feed
    end
  end

  context 'with a logger' do
    subject { Automatic::Plugin::PublishFluentd.new(settings, pipeline) }

    let(:logger) { double('fluentd') }

    before { Fluent::Logger::FluentLogger.stub(:open).and_return(logger) }

    it "posts the item's fields and a timestamp under the configured tag" do
      posted = nil
      logger.should_receive(:post) { |tag, record| tag.should == 'automatic_spec.publish_fluent'
                                                   posted = record }
      subject.run.should have(1).feed

      posted[:title].should == 'hoge'
      posted[:link].should == 'http://github.com'
      posted[:description].should == '<a>fuga</a>'
      posted[:created_at].should match(%r{\A\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}\z})
    end

    it 'logs a forward that fails and carries on' do
      logger.stub(:post).and_raise(IOError, 'connection refused')
      Automatic::Log.stub(:puts)
      Automatic::Log.should_receive(:puts).with('warn', /connection refused/)
      subject.run.should have(1).feed
    end
  end
end
