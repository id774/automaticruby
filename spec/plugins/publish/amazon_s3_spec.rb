# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::AmazonS3
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Feb 25, 2014
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# PublishAmazonS3 is written against AWS SDK for Ruby v1;
# doc/PLUGINS.md section 6.7 classifies it as Needs rework.
#
# The gem is not a dependency of this project, so this spec is skipped rather
# than stubbed; see doc/POLICY.md section 4.
return unless AutomaticSpec.plugin_available?('publish/amazon_s3')

describe Automatic::Plugin::PublishAmazonS3 do
  context 'when feed' do
    describe 'should forward the feeds' do
      subject {
        Automatic::Plugin::PublishAmazonS3.new(
          {
            'access_key' => "aabbcc",
            'secret_key' => "ddeeff",
            'bucket_name' => "test_bucket",
            'target_path' => "test/tmp",
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
        subject.run.should have(1).feed
      }
    end

  end
end
