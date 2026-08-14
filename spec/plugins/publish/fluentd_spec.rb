# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Fluentd
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 21, 2013
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# PublishFluentd needs the optional fluent-logger gem;
# doc/PLUGINS.md section 6.7 classifies it as Supported (external).
#
# The gem is not a dependency of this project, so this spec is skipped rather
# than stubbed; see doc/POLICY.md section 4.
return unless AutomaticSpec.plugin_available?('publish/fluentd')

describe Automatic::Plugin::PublishFluentd do
  context 'when feed' do
    describe 'should forward the feeds' do
      subject {
        Automatic::Plugin::PublishFluentd.new(
          {
            'host' => "localhost",
            'port' => "10000",
            'tag'  => "automatic_spec.publish_fluent",
            'mode' => "test"
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
        fluentd = double("fluentd")
        subject.run.should have(1).feed
      }
    end

  end
end
