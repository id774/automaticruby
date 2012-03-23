#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Reverse
# Author::    774 <http://id774.net>
# Created::   Mar 23, 2012
# Updated::   Mar 23, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/reverse'

describe Automatic::Plugin::FilterReverse do
  context "it should be reverse sorted" do
    subject {
      Automatic::Plugin::FilterReverse.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://27.media.tumblr.com/tumblr_lzrubkfPlt1qb8vzto1_500.png", "",
            "<img src=\"http://27.media.tumblr.com/tumblr_lzrubkfPlt1qb8vzto1_500.png\">",
            "Fri, 23 Mar 2012 00:01:00 +0000"
            item "http://24.media.tumblr.com/tumblr_m07wttnIdy1qzoj1jo1_400.jpg", "",
            "<img src=\"http://24.media.tumblr.com/tumblr_m07wttnIdy1qzoj1jo1_400.jpg\">",
            "Fri, 23 Mar 2012 00:00:00 +0000"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://24.media.tumblr.com/tumblr_m07wttnIdy1qzoj1jo1_400.jpg"
        subject.instance_variable_get(:@pipeline)[0].items[1].link.
        should == "http://27.media.tumblr.com/tumblr_lzrubkfPlt1qb8vzto1_500.png"
      }
    end
  end
end
