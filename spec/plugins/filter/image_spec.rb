# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Image
# Author::    774 <http://id774.net>
# Created::   Sep 18, 2012
# Updated::   Sep 18, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/image'

describe Automatic::Plugin::FilterImage do
  context "with feed contain link tag" do
    subject {
      Automatic::Plugin::FilterImage.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://id774.net/images/link_1.jpg"
            item "http://id774.net/images/link_2.jpg"
            item "http://id774.net/images/link_3.JPG"
            item "http://id774.net/images/link_4.png"
            item "http://id774.net/images/link_5.jpeg"
            item "http://id774.net/images/link_6.PNG"
            item "http://id774.net/images/link_7.jpega"
            item "http://id774.net/images/link_8.gif"
            item "http://id774.net/images/link_9.GIF"
            item "http://id774.net/images/link_10.tiff"
            item "http://id774.net/images/link_11.TIFF"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net/images/link_1.jpg"
        subject.instance_variable_get(:@pipeline)[0].items[1].link.
        should == "http://id774.net/images/link_2.jpg"
        subject.instance_variable_get(:@pipeline)[0].items[2].link.
        should == "http://id774.net/images/link_3.JPG"
        subject.instance_variable_get(:@pipeline)[0].items[3].link.
        should == "http://id774.net/images/link_4.png"
        subject.instance_variable_get(:@pipeline)[0].items[4].link.
        should == "http://id774.net/images/link_5.jpeg"
        subject.instance_variable_get(:@pipeline)[0].items[5].link.
        should == "http://id774.net/images/link_6.PNG"
        subject.instance_variable_get(:@pipeline)[0].items[6].link.
        should be_nil
        subject.instance_variable_get(:@pipeline)[0].items[7].link.
        should == "http://id774.net/images/link_8.gif"
        subject.instance_variable_get(:@pipeline)[0].items[8].link.
        should == "http://id774.net/images/link_9.GIF"
        subject.instance_variable_get(:@pipeline)[0].items[9].link.
        should == "http://id774.net/images/link_10.tiff"
        subject.instance_variable_get(:@pipeline)[0].items[10].link.
        should == "http://id774.net/images/link_11.TIFF"
      }
    end
  end
end
