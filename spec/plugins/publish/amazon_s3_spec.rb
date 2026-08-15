# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::AmazonS3
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 25, 2014
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/amazon_s3'
require 'tmpdir'

# PublishAmazonS3 needs an S3 bucket and the aws-sdk-s3 gem, which is an
# optional dependency in its own Gemfile group; doc/PLUGINS.md section 6.7
# classifies it as Supported (external). What is verified here is everything
# on this side of the bucket -- which items it selects, the key it computes,
# what `mode: test` does -- and none of it needs the gem, the account or the
# network. See doc/POLICY.md section 5.
describe Automatic::Plugin::PublishAmazonS3 do
  let(:settings) {
    {
      'access_key'  => 'aabbcc',
      'secret_key'  => 'ddeeff',
      'bucket_name' => 'test_bucket',
      'target_path' => 'test/tmp',
      'mode'        => 'test'
    }
  }

  context 'with a link that is not a file URI' do
    subject {
      Automatic::Plugin::PublishAmazonS3.new(
        settings,
        AutomaticSpec.generate_pipeline {
          feed { item 'http://github.com', 'hoge', '<a>fuga</a>' }
        }
      )
    }

    it 'returns the pipeline unchanged and uploads nothing' do
      subject.should_not_receive(:s3)
      subject.run.should have(1).feed
    end
  end

  context 'with a file URI, in test mode' do
    it 'names the key under target_path and does not build a client' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'photo.png')
        File.binwrite(path, 'x')

        plugin = Automatic::Plugin::PublishAmazonS3.new(
          settings,
          AutomaticSpec.generate_pipeline { feed { item "file://#{path}" } }
        )
        plugin.should_not_receive(:s3)
        plugin.run.should have(1).feed
        plugin.send(:target_key, path).should == 'test/tmp/photo.png'
      end
    end
  end

  describe 'the client settings' do
    it 'passes the Recipe credentials through' do
      plugin = Automatic::Plugin::PublishAmazonS3.new(settings.merge('region' => 'ap-northeast-1'))
      plugin.send(:client_options).should == {
        region: 'ap-northeast-1',
        access_key_id: 'aabbcc',
        secret_access_key: 'ddeeff'
      }
    end

    # Without credentials in the Recipe the SDK's own chain is left to answer,
    # which is how this runs from an instance role instead of from a secret in
    # a file.
    it 'passes nothing where the Recipe carries no credential' do
      plugin = Automatic::Plugin::PublishAmazonS3.new('bucket_name' => 'b')
      plugin.send(:client_options).should == {}
    end
  end

  describe 'an item whose file is gone' do
    subject {
      Automatic::Plugin::PublishAmazonS3.new(
        settings.merge('mode' => 'live'),
        AutomaticSpec.generate_pipeline { feed { item 'file:///nonexistent/photo.png' } }
      )
    }

    it 'logs the failure and carries on' do
      Automatic::Log.should_receive(:puts).with('error', /photo\.png/)
      subject.run.should have(1).feed
    end
  end
end
