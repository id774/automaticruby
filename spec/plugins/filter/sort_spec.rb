# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Sort
# Author::    774 <http://id774.net>
# Created::   Mar 23, 2012
# Updated::   Jan 23, 2013
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/sort'

describe Automatic::Plugin::FilterSort do
  context "It should be asc sorted" do
    subject {
      Automatic::Plugin::FilterSort.new(
        {
          'sort' => "asc"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://aaa.png", "",
            "<img src=\"http://aaa.png\">",
            "Fri, 23 Mar 2012 00:10:00 +0000"
            item "http://bbb.png", "",
            "<img src=\"http://bbb.png\">",
            "Sun, 25 Mar 2012 01:05:00 +0000"
            item "http://ccc.png", "",
            "<img src=\"http://ccc.png\">",
            "Thu, 22 Mar 2012 00:15:00 +0000"
            item "http://ddd.png", "",
            "<img src=\"http://ddd.png\">",
            "Fri, 23 Mar 2012 00:00:08 +0000"
            item "http://eee.png", "",
            "<img src=\"http://eee.png\">",
            "Fri, 23 Nov 2012 00:09:00 +0000"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://ccc.png"
        subject.instance_variable_get(:@pipeline)[0].items[1].link.
        should == "http://ddd.png"
        subject.instance_variable_get(:@pipeline)[0].items[2].link.
        should == "http://aaa.png"
        subject.instance_variable_get(:@pipeline)[0].items[3].link.
        should == "http://bbb.png"
        subject.instance_variable_get(:@pipeline)[0].items[4].link.
        should == "http://eee.png"
      }
    end
  end

  context "It should be asc sorted" do
    subject {
      Automatic::Plugin::FilterSort.new(
        {
          'sort' => "asc"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://aaa.png", "",
            "<img src=\"http://aaa.png\">",
            "Sat, 24 Mar 2012 01:15:00 +0000"
            item "http://bbb.png", "",
            "<img src=\"http://bbb.png\">",
            "Thu, 22 Mar 2012 02:05:00 +0000"
            item "http://ccc.png", "",
            "<img src=\"http://ccc.png\">",
            "Fri, 23 Mar 2012 02:00:00 +0000"
            item "http://ddd.png", "",
            "<img src=\"http://ddd.png\">",
            "Fri, 23 Mar 2012 01:40:00 +0000"
            item "http://eee.png", "",
            "<img src=\"http://eee.png\">",
            "Fri, 23 Nov 2012 00:00:35 +0000"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://bbb.png"
        subject.instance_variable_get(:@pipeline)[0].items[1].link.
        should == "http://ddd.png"
        subject.instance_variable_get(:@pipeline)[0].items[2].link.
        should == "http://ccc.png"
        subject.instance_variable_get(:@pipeline)[0].items[3].link.
        should == "http://aaa.png"
        subject.instance_variable_get(:@pipeline)[0].items[4].link.
        should == "http://eee.png"
      }
    end
  end

  context "It should be desc sorted" do
    subject {
      Automatic::Plugin::FilterSort.new(
        {
          'sort' => "desc"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://aaa.png", "",
            "<img src=\"http://aaa.png\">",
            "Fri, 23 Mar 2012 00:10:00 +0000"
            item "http://bbb.png", "",
            "<img src=\"http://bbb.png\">",
            "Sun, 25 Mar 2012 01:05:00 +0000"
            item "http://ccc.png", "",
            "<img src=\"http://ccc.png\">",
            "Thu, 22 Mar 2012 00:15:00 +0000"
            item "http://ddd.png", "",
            "<img src=\"http://ddd.png\">",
            "Fri, 23 Mar 2012 00:00:08 +0000"
            item "http://eee.png", "",
            "<img src=\"http://eee.png\">",
            "Fri, 23 Nov 2012 00:09:00 +0000"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[4].link.
        should == "http://ccc.png"
        subject.instance_variable_get(:@pipeline)[0].items[3].link.
        should == "http://ddd.png"
        subject.instance_variable_get(:@pipeline)[0].items[2].link.
        should == "http://aaa.png"
        subject.instance_variable_get(:@pipeline)[0].items[1].link.
        should == "http://bbb.png"
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://eee.png"
      }
    end
  end

  context "It should be desc sorted" do
    subject {
      Automatic::Plugin::FilterSort.new(
        {
          'sort' => "desc"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://aaa.png", "",
            "<img src=\"http://aaa.png\">",
            "Sat, 24 Mar 2012 01:15:00 +0000"
            item "http://bbb.png", "",
            "<img src=\"http://bbb.png\">",
            "Thu, 22 Mar 2012 02:05:00 +0000"
            item "http://ccc.png", "",
            "<img src=\"http://ccc.png\">",
            "Fri, 23 Mar 2012 02:00:00 +0000"
            item "http://ddd.png", "",
            "<img src=\"http://ddd.png\">",
            "Fri, 23 Mar 2012 01:40:00 +0000"
            item "http://eee.png", "",
            "<img src=\"http://eee.png\">",
            "Fri, 23 Nov 2012 00:00:35 +0000"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[4].link.
        should == "http://bbb.png"
        subject.instance_variable_get(:@pipeline)[0].items[3].link.
        should == "http://ddd.png"
        subject.instance_variable_get(:@pipeline)[0].items[2].link.
        should == "http://ccc.png"
        subject.instance_variable_get(:@pipeline)[0].items[1].link.
        should == "http://aaa.png"
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://eee.png"
      }
    end
  end
end
