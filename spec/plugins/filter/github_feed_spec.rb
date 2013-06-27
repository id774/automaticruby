# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::GithubFeed
# Author::    Kohei Hasegawa <http://github.com/banyan>
# Created::   Jun 6, 2013
# Updated::   Jun 6, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

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
        subject.run

        subject.instance_variable_get(:@pipeline)[0].items[0].link
          .should == '1'
        subject.instance_variable_get(:@pipeline)[0].items[0].title
          .should == 'title1'
        subject.instance_variable_get(:@pipeline)[0].items[0].description
          .should == 'description1'

        subject.instance_variable_get(:@pipeline)[0].items[1].link
          .should == '0'
        subject.instance_variable_get(:@pipeline)[0].items[1].title
          .should == 'title0'
        subject.instance_variable_get(:@pipeline)[0].items[1].description
          .should == 'description0'
      }
    end
  end
end
