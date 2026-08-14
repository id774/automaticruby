# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::ImageSource
# Author: kzgs
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Mar  1, 2012
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

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
        subject.instance_variable_get(:@return_feeds)[0].items[0].link.
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
        subject.instance_variable_get(:@return_feeds)[0].items[0].link.
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
        subject.stub(:rewrite_link).and_return(['http://huge.png'])
      end

      its(:run) { should have(1).feeds }
      specify {
        subject.run
        subject.instance_variable_get(:@return_feeds)[0].items[0].link.
        should == 'http://huge.png'
      }
    end

    describe "#imgs" do
      before do
        response = Hashie::Mash.new
        response.read = '<img src="http://a.png"><br /><img src="http://b.png">'
        URI.stub(:open).and_return(response)
      end

      its(:run) { subject.run[0].items.length.should == 2 }
    end
  end
end
