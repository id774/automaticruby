# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::FullFeed
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jan 24, 2013
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/full_feed'
require 'fileutils'
require 'tmpdir'

describe Automatic::Plugin::FilterFullFeed do
  context "It should be matched by siteinfo", :network do
    subject {
      Automatic::Plugin::FilterFullFeed.new(
        {
          'siteinfo' => "items_all.json"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://matome.naver.jp/odai/2129948007339738701/2129948085139809603", "hoge",
            "fuga",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://matome.naver.jp/odai/2129948007339738701/2129948085139809603"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "fuga"

        subject.run

        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://matome.naver.jp/odai/2129948007339738701/2129948085139809603"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should match(/このまとめを見る/)
      }
    end
  end

  context "It should be not matched by siteinfo" do
    subject {
      Automatic::Plugin::FilterFullFeed.new(
        {
          'siteinfo' => "items_all.json"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://id774.net", "aaaaaa",
            "bbbbbb",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "bbbbbb"

        subject.run

        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "bbbbbb"
      }
    end
  end

  context "It should be not matched by siteinfo with local dir" do
    subject {
      Automatic::Plugin::FilterFullFeed.new(
        {
          'siteinfo' => "items_all.json"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://id774.net", "cccc",
            "ddddd",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }})}

    describe "#run" do
      # This exercises the plugin's preference for ~/.automatic/assets over the
      # installation's own. HOME is redirected to a temporary directory for the
      # duration: the previous version of this spec deleted the real
      # ~/.automatic/assets/siteinfo, so running the suite destroyed whatever
      # siteinfo the developer had put there.
      before do
        @real_home = ENV['HOME']
        @tmp_home = Dir.mktmpdir('automatic-spec-home')
        ENV['HOME'] = @tmp_home

        dir = File.expand_path('~/.automatic/assets/siteinfo')
        FileUtils.mkdir_p(dir)
        FileUtils.cp(File.join(APP_ROOT, 'assets/siteinfo/items_all.json'), dir)
      end

      its(:run) { should have(1).feeds }

      specify {
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "ddddd"

        subject.run

        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "ddddd"
      }

      after do
        ENV['HOME'] = @real_home
        FileUtils.rm_rf(@tmp_home)
      end
    end
  end
end
