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
          link "filterImageLink.html"
        }
      )
    }

    describe "#run" do
      its(:run) { should have(10).items }
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
        expect = "http://link_8.gif"
        subject.instance_variable_get(:@return_html)[6].should == expect
        expect = "http://link_9.GIF"
        subject.instance_variable_get(:@return_html)[7].should == expect
        expect = "http://link_10.tiff"
        subject.instance_variable_get(:@return_html)[8].should == expect
        expect = "http://link_11.TIFF"
        subject.instance_variable_get(:@return_html)[9].should == expect
      }
    end
  end
end

