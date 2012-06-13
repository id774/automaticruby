# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Jpeg
# Author::    774 <http://id774.net>
# Created::   Jun 13, 2012
# Updated::   Jun 13, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/jpeg'

describe Automatic::Plugin::FilterJpeg do
  context "with html contain link tag" do
    subject {
      Automatic::Plugin::FilterJpeg.new({},
        AutomaticSpec.generate_pipeline {
          link "filterJpeg.html"
        }
      )}

    describe "#run" do
      its(:run) { should have(2).feeds }
      specify {
        subject.run
        expect = "http://oh-news.net/live/wp-content/uploads/2011/04/Eila_omote.jpg"
        subject.instance_variable_get(:@return_html)[0].should == expect
        expect = "http://oh-news.net/live/wp-content/uploads/2011/04/Sanya_omote.jpg"
        subject.instance_variable_get(:@return_html)[1].should == expect
      }
    end
  end
end

