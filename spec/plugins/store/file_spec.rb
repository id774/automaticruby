# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Store::File
# Author:       kzgs
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar  4, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'store/file'
require 'tmpdir'
require 'pathname'

describe Automatic::Plugin::StoreFile do
  it "should store the target link", :network do
    Dir.mktmpdir do |dir|
      instance = Automatic::Plugin::StoreFile.new(
        { "path" => dir },
        AutomaticSpec.generate_pipeline {
          feed { item "http://id774.net/test/store/rss" }
        }
      )
      instance.run.should have(1).feed
      (Pathname(dir)+"rss").should be_exist
    end
  end

  it "should error during file download" do
    Dir.mktmpdir do |dir|
      instance = Automatic::Plugin::StoreFile.new(
        { "path" => dir },
        AutomaticSpec.generate_pipeline {
          feed { item "aaa" }
        }
      )
      instance.run.should have(0).feed
    end
  end

  it "should error and retry during file download" do
    Dir.mktmpdir do |dir|
      instance = Automatic::Plugin::StoreFile.new(
        {
          "path" => dir,
          'retry' => 1,
          'interval' => 0
        },
        AutomaticSpec.generate_pipeline {
          feed { item "aaa" }
        }
      )
      instance.run.should have(0).feed
    end
  end

end

describe Automatic::Plugin::StoreFile do
  # A link arrives from a feed, which is to say from outside; a store plugin
  # that would read file:// on being asked to is a store plugin that can be
  # asked to read anything.
  it "refuses a link that is not HTTP or HTTPS" do
    Dir.mktmpdir do |dir|
      instance = Automatic::Plugin::StoreFile.new(
        { "path" => dir },
        AutomaticSpec.generate_pipeline { feed { item "file:///etc/passwd" } }
      )
      instance.run.should have(0).feed
      Dir.children(dir).should be_empty
    end
  end

  it "writes what it fetched and rewrites the link to a file URI" do
    Dir.mktmpdir do |dir|
      Automatic::Http.stub(:read).and_return('a body')
      instance = Automatic::Plugin::StoreFile.new(
        { "path" => dir },
        AutomaticSpec.generate_pipeline { feed { item "https://example.com/a/photo.png" } }
      )

      returned = instance.run
      returned.should have(1).feed
      returned[0].items[0].link.should == "file://#{File.join(dir, 'photo.png')}"
      File.read(File.join(dir, 'photo.png')).should == 'a body'
    end
  end

  # `s3n` is what Recipes written for this plugin use; `s3` is the spelling
  # everything else uses and is accepted as well. Both go to the SDK rather
  # than over HTTP.
  %w[s3 s3n].each do |scheme|
    it "fetches a #{scheme}:// link from the bucket" do
      Dir.mktmpdir do |dir|
        client = double('s3')
        instance = Automatic::Plugin::StoreFile.new(
          { "path" => dir, "bucket_name" => "a-bucket" },
          AutomaticSpec.generate_pipeline { feed { item "#{scheme}://ignored/a/photo.png" } }
        )
        instance.stub(:s3).and_return(client)
        client.should_receive(:get_object).
          with(bucket: 'a-bucket', key: 'a/photo.png',
               response_target: File.join(dir, 'photo.png'))

        instance.run[0].items[0].link.should == "file://#{File.join(dir, 'photo.png')}"
      end
    end
  end

  describe "the client settings" do
    subject {
      Automatic::Plugin::StoreFile.new(
        'path' => '/tmp', 'region' => 'ap-northeast-1',
        'access_key' => 'aabbcc', 'secret_key' => 'ddeeff'
      )
    }

    it "passes the Recipe credentials through" do
      subject.send(:client_options).should == {
        region: 'ap-northeast-1', access_key_id: 'aabbcc', secret_access_key: 'ddeeff'
      }
    end

    it "passes nothing where the Recipe carries no credential" do
      Automatic::Plugin::StoreFile.new('path' => '/tmp').send(:client_options).should == {}
    end
  end
end
