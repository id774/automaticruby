# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::ImageSource
# Author:       kzgs
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar  1, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# FilterImageSource reads HTML with nokogiri, which the Gemfile declares in its
# optional :plugins group. The default suite and CI do not install it, so this
# spec runs only where the operator has. See doc/POLICY.md section 5.
return unless AutomaticSpec.optional_dependency?('nokogiri')

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
        returned = subject.run
        returned[0].items[0].link.
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
        returned = subject.run
        returned[0].items[0].link.
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

    # The page behind the link is read through Automatic::Http, which is this
    # framework's own boundary rather than a service being simulated: the spec
    # says what the page contains and asserts on what the plugin makes of it.
    describe "#run" do
      before do
        Automatic::Http.stub(:read).
          and_return('<img src="http://huge.png">')
      end

      its(:run) { should have(1).feeds }
      specify {
        returned = subject.run
        returned[0].items[0].link.
        should == 'http://huge.png'
      }
    end

    describe "with several images on the page" do
      before do
        Automatic::Http.stub(:read).
          and_return('<img src="http://a.png"><br /><img src="http://b.png">')
      end

      its(:run) { subject.run[0].items.length.should == 2 }
    end

    describe "with a page whose images are relative" do
      before do
        Automatic::Http.stub(:read).
          and_return("<img src='/a.png'><img src='b.png'>")
      end

      specify {
        subject.run[0].items.map(&:link).sort.
          should == ['http://tumblr.com/a.png', 'http://tumblr.com/b.png']
      }
    end

    describe "when the page cannot be read" do
      before do
        Automatic::Http.stub(:read).and_raise(StandardError, 'no such host')
      end

      its(:run) { should have(1).feeds }
      specify { subject.run[0].items.should be_empty }
    end
  end
end

describe Automatic::Plugin::FilterImageSource do
  context "with a description quoting src with apostrophes" do
    subject {
      Automatic::Plugin::FilterImageSource.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://example.com/post", "",
            "<p><img alt='x' src='http://example.com/a.png'></p>"
          }})}

    specify {
      subject.run[0].items.map(&:link).
        should == ['http://example.com/a.png']
    }
  end
end
