# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Fluentd
# Author::    774 <http://id774.net>
# Created::   Jun 21, 2013
# Updated::   Jun 21, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/fluentd'

describe Automatic::Plugin::PublishFluentd do
  context 'when feed' do
    describe 'should forward the feeds' do
      subject {
        Automatic::Plugin::PublishFluentd.new(
          {
            'host' => "localhost",
            'port' => "9999",
            'tag'  => "debug.forward"
          },
          AutomaticSpec.generate_pipeline{
            feed {
              item "http://github.com", "hoge",
              "<a>fuga</a>"
            }
          }
        )
      }

      its (:run) {
        fluentd = mock("fluentd")
        subject.run.should have(1).feed
      }
    end

  end
end
