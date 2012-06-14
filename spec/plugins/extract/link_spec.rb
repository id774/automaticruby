# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Extract::Link
# Author::    774 <http://id774.net>
# Created::   Jun 12, 2012
# Updated::   Jun 14, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'extract/link'

describe Automatic::Plugin::ExtractLink do
  context "with html contain link tag" do
    subject {
      Automatic::Plugin::ExtractLink.new({},
        AutomaticSpec.generate_pipeline {
          html "extractLink.html"
        }
      )}

    describe "#run" do
      its(:run) { should have(4).items }
      specify {
        subject.run
        expect = "http://id774.net"
        subject.instance_variable_get(:@return_html)[0].should == expect
        expect = "http://reblog.id774.net"
        subject.instance_variable_get(:@return_html)[1].should == expect
        expect = "http://oh-news.net/live/wp-content/uploads/2011/04/Eila_omote.jpg"
        subject.instance_variable_get(:@return_html)[2].should == expect
        expect = "http://blog.id774.net/post/"
        subject.instance_variable_get(:@return_html)[3].should == expect
      }
    end
  end
end

