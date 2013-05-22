# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::FullFeed
# Author::    774 <http://id774.net>
# Created::   Jan 24, 2013
# Updated::   Mar 24, 2013
# Copyright:: 774 Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/full_feed'

describe Automatic::Plugin::FilterFullFeed do
  context "It should be matched by siteinfo" do
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
      def cleanup_dir
        root_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
        dir = (File.expand_path('~/.automatic/assets/siteinfo'))
        if File.directory?(dir)
          puts "Removing #{dir}"
          FileUtils.rm_r(dir)
        end
        return dir, root_dir
      end

      before do
        dir, root_dir = cleanup_dir
        FileUtils.mkdir_p(dir)
        FileUtils.cp_r(root_dir + '/assets/siteinfo/items_all.json', dir)
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
        cleanup_dir
      end
    end
  end
end
