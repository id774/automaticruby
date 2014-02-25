# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::AmazonS3
# Author::    774 <http://id774.net>
# Created::   Feb 25, 2014
# Updated::   Feb 25, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/amazon_s3'

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
