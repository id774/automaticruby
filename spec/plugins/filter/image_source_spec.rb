# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::ImageSource
# Author::    kzgs
#             774 <http://id774.net>
# Created::   Mar  1, 2012
# Updated::   Jun 14, 2012
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/image_source'

describe Automatic::Plugin::FilterImageSource do
  context "with description with image tag" do
    subject {
      Automatic::Plugin::FilterImageSource.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://tumblr.com", "",
            "<img src=\"http://27.media.tumblr.com/tumblr_lzrubkfPlt1qb8vzto1_500.png\">"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }
      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://27.media.tumblr.com/tumblr_lzrubkfPlt1qb8vzto1_500.png"
      }
    end
  end
end

describe Automatic::Plugin::FilterImageSource do
  context "with description with image tag" do
    subject {
      Automatic::Plugin::FilterImageSource.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://tumblr.com", "",
            "<img src=\"http://24.media.tumblr.com/tumblr_m07wttnIdy1qzoj1jo1_400.jpg\">"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }
      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://24.media.tumblr.com/tumblr_m07wttnIdy1qzoj1jo1_400.jpg"
      }
    end
  end
end

describe Automatic::Plugin::FilterImageSource do
  context "with link to tag image" do
    subject {
      Automatic::Plugin::FilterImageSource.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://tumblr.com", "",
            ""
          }})}

    describe "#run" do
      before do
        subject.stub!(:rewrite_link).and_return(['http://huge.png'])
      end

      its(:run) { should have(1).feeds }
      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == 'http://huge.png'
      }
    end

    describe "#imgs" do
      before do
        open = Hashie::Mash.new
        open.read = '<img src="http://a.png"><br /><img src="http://b.png">'
        subject.stub!(:open).and_return(open)
      end

      its(:run) { subject.run[0].items.length.should == 2 }
    end
  end
end
