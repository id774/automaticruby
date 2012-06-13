# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::ImageLink
# Author::    774 <http://id774.net>
# Created::   Jun 13, 2012
# Updated::   Jun 13, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/image_link'

describe Automatic::Plugin::FilterImageLink do
  context "with html contain link tag" do
    subject {
      Automatic::Plugin::FilterImageLink.new({},
        AutomaticSpec.generate_pipeline {
          link "filterJpeg.html"
        }
      )}

    describe "#run" do
      its(:run) { should have(6).feeds }
      specify {
        subject.run
        expect = "http://link_1.jpg"
        subject.instance_variable_get(:@return_html)[0].should == expect
        expect = "http://link_2.jpg"
        subject.instance_variable_get(:@return_html)[1].should == expect
        expect = "http://link_3.JPG"
        subject.instance_variable_get(:@return_html)[2].should == expect
        expect = "http://link_4.png"
        subject.instance_variable_get(:@return_html)[3].should == expect
        expect = "http://link_5.jpeg"
        subject.instance_variable_get(:@return_html)[4].should == expect
        expect = "http://link_6.PNG"
        subject.instance_variable_get(:@return_html)[5].should == expect
      }
    end
  end
end

