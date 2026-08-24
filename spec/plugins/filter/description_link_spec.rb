# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::DescriptionLink
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Oct 03, 2014
# Updated::     Aug 24, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# FilterDescriptionLink reads a fetched page with nokogiri, which the Gemfile
# declares in its optional :plugins group. The default suite and CI do not
# install it, so this spec runs only where the operator has. See
# doc/POLICY.md section 5.
if AutomaticSpec.optional_dependency?('nokogiri')
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

    context "It should be got title if get_title specified", :network do

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

    context "It should be handling error if 404 Not Found", :network do

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

    # The framework hands a plugin a Hashie::Mash, not a Hash. This tested the
    # mapping's class and so read neither setting in any real run; the spec
    # below is the one that would have caught it.
    context "with the mapping a Recipe actually produces" do

      subject {
        Automatic::Plugin::FilterDescriptionLink.new(
          Hashie::Mash.new('clear_description' => 1),
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

      specify {
        returned = subject.run
        returned[0].items[0].link.should == "http://test2.id774.net"
        returned[0].items[0].description.should == ""
      }
    end

    describe "the interval setting" do
      context "when interval is positive and every title page fetch succeeds" do
        subject {
          Automatic::Plugin::FilterDescriptionLink.new(
            { 'get_title' => 1, 'interval' => 2 },
            AutomaticSpec.generate_pipeline {
              feed {
                item "http://test1.id774.net", "dummy title 1",
                "aaa bbb ccc http://test2.id774.net ddd eee"
                item "http://test3.id774.net", "dummy title 2",
                "aaa bbb ccc http://test4.id774.net ddd eee"
              }
            }
          )
        }

        before do
          Automatic::Http.stub(:read).
            and_return('<html><head><title>Fetched title</title></head><body></body></html>')
        end

        it "waits after every title page fetch" do
          subject.should_receive(:sleep).with(2).twice
          subject.run
          subject.instance_variable_get(:@pipeline)[0].items.each do |item|
            item.title.should == "Fetched title"
          end
        end
      end

      context "when get_title is disabled" do
        subject {
          Automatic::Plugin::FilterDescriptionLink.new(
            { 'interval' => 2 },
            AutomaticSpec.generate_pipeline {
              feed {
                item "http://test1.id774.net", "dummy title",
                "aaa bbb ccc http://test2.id774.net ddd eee"
              }
            }
          )
        }

        it "does not wait" do
          Automatic::Http.should_not_receive(:read)
          subject.should_not_receive(:sleep)
          subject.run
          subject.instance_variable_get(:@pipeline)[0].items[0].link.
            should == "http://test2.id774.net"
        end
      end

      context "when the title page fetch fails" do
        subject {
          Automatic::Plugin::FilterDescriptionLink.new(
            { 'get_title' => 1, 'interval' => 2 },
            AutomaticSpec.generate_pipeline {
              feed {
                item "http://test1.id774.net", "dummy title",
                "aaa bbb ccc http://test2.id774.net ddd eee"
              }
            }
          )
        }

        before { Automatic::Http.stub(:read).and_raise(StandardError, 'no such host') }

        it "waits once and keeps the existing title" do
          subject.should_receive(:sleep).with(2).once
          lambda { subject.run }.should_not raise_error
          subject.instance_variable_get(:@pipeline)[0].items[0].title.
            should == "dummy title"
        end
      end
    end

  end
end
