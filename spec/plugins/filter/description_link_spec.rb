# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::DescriptionLink
# Author::    774 <http://id774.net>
# Created::   Oct 03, 2014
# Updated::   Oct 03, 2014
# Copyright:: Copyright (c) 2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/description_link'

describe Automatic::Plugin::FilterDescriptionLink do

  context "It should be rewrite link based on the description" do

    subject {
      Automatic::Plugin::FilterDescriptionLink.new(
        {},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://test1.id774.net",
            "dummy title",
            "aaa bbb ccc http://test2.id774.net ddd eee",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://test2.id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "aaa bbb ccc http://test2.id774.net ddd eee"
      }
    end
  end

  context "It should be empty description if clear_description specified" do

    subject {
      Automatic::Plugin::FilterDescriptionLink.new({
          'clear_description' => 1,
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://test1.id774.net",
            "dummy title",
            "aaa bbb ccc http://test2.id774.net ddd eee",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://test2.id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == ""
      }
    end
  end

  context "It should be got title if get_title specified" do

    subject {
      Automatic::Plugin::FilterDescriptionLink.new({
          'get_title' => 1,
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://test1.id774.net",
            "dummy title",
            "aaa bbb ccc http://blog.id774.net/post/2014/10/01/531/ ddd eee",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://blog.id774.net/post/2014/10/01/531/"
        subject.instance_variable_get(:@pipeline)[0].items[0].title.
        should == "二穂様は俺の嫁 | 774::Blog"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "aaa bbb ccc http://blog.id774.net/post/2014/10/01/531/ ddd eee"
      }
    end
  end

  context "It should be handling error if 404 Not Found" do

    subject {
      Automatic::Plugin::FilterDescriptionLink.new({
          'get_title' => 1,
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://test1.id774.net",
            "dummy title",
            "aaa bbb ccc http://blog.id774.net/post/2014/10/01/532/ ddd eee",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://blog.id774.net/post/2014/10/01/532/"
        subject.instance_variable_get(:@pipeline)[0].items[0].title.
        should == "dummy title"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "aaa bbb ccc http://blog.id774.net/post/2014/10/01/532/ ddd eee"
      }
    end
  end

end
