# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Provide::Fluentd
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jul 12, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# ProvideFluentd needs the fluent-logger gem and a Fluentd instance;
# doc/PLUGINS.md section 6.5 classifies it as Supported (external). The gem is
# an optional dependency in its own Gemfile group, so this spec is skipped
# rather than stubbed where it is absent (doc/POLICY.md section 4). Where it is
# present, what is verified is what the plugin posts -- not that a Fluentd
# instance received it.
return unless AutomaticSpec.plugin_available?('provide/fluentd')

describe Automatic::Plugin::ProvideFluentd do
  let(:settings) {
    { 'host' => 'localhost', 'port' => '10000', 'tag' => 'automatic_spec.provide_fluentd' }
  }

  let(:pipeline) {
    [Automatic::FeedMaker.content_provide('http://id774.net/test/xml/data',
                                          'test1' => 'test2', 'test3' => 'test4')]
  }

  context 'in test mode' do
    subject { Automatic::Plugin::ProvideFluentd.new(settings.merge('mode' => 'test'), pipeline) }

    it 'builds no connection and returns the pipeline unchanged' do
      Fluent::Logger::FluentLogger.should_not_receive(:open)
      subject.run.should have(1).feed
    end
  end

  context 'with a logger' do
    subject { Automatic::Plugin::ProvideFluentd.new(settings, pipeline) }

    before {
      Fluent::Logger::FluentLogger.stub(:open).and_return(logger)
    }

    let(:logger) { double('fluentd') }

    it "posts the item's content_encoded under the configured tag" do
      logger.should_receive(:post).
        with('automatic_spec.provide_fluentd', { 'test1' => 'test2', 'test3' => 'test4' })
      subject.run.should have(1).feed
    end

    it 'opens the logger with the host and port from the settings' do
      Fluent::Logger::FluentLogger.should_receive(:open).
        with(nil, host: 'localhost', port: 10_000).and_return(logger)
      logger.stub(:post)
      subject.run
    end

    # content_encoded has to be something Fluentd accepts as a record; a plain
    # string is logged as an error and skipped rather than ending the run.
    it 'logs a record the logger rejects' do
      logger.stub(:post).and_raise(ArgumentError, 'not a hash')
      Automatic::Log.stub(:puts)
      Automatic::Log.should_receive(:puts).with('error', /not a hash/)
      subject.run.should have(1).feed
    end
  end
end
