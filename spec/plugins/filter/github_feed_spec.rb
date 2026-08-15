# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::GithubFeed
# Author:       Kohei Hasegawa (More info: http://github.com/banyan)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 6, 2013
# Updated::     Feb 21, 2014
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/github_feed'

describe Automatic::Plugin::FilterGithubFeed do
  context "with description with filename of tumblr should be renamed 500 to 1280" do
    subject {
      described_class.new(
        {},
        AutomaticSpec.generate_pipeline {
          feed {
            2.times do |i|
              @channel.items << Hashie::Mash.new(
                :title   => { :content => "title#{i}" },
                :id      => { :content => i.to_s },
                :content => { :content => "description#{i}" }
              )
            end
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        returned = subject.run

        returned[0].items[0].link
          .should == '1'
        returned[0].items[0].title
          .should == 'title1'
        returned[0].items[0].description
          .should == 'description1'

        returned[0].items[1].link
          .should == '0'
        returned[0].items[1].title
          .should == 'title0'
        returned[0].items[1].description
          .should == 'description0'
      }
    end
  end
end
