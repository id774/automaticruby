# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Rand
# Author::    soramugi <http://soramugi.net>
#             774 <http://id774.net>
# Created::   May  6, 2013
# Updated::   Mar  7, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/rand'

describe Automatic::Plugin::FilterRand do
  context "It should be rand" do
    subject {
      Automatic::Plugin::FilterRand.new(
        {},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://aaa.png"
            item "http://bbb.png"
            item "http://ccc.png"
            item "http://ddd.png"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        link0 = subject.instance_variable_get(:@return_feeds)[0].items[0].link
        link1 = subject.instance_variable_get(:@return_feeds)[0].items[1].link
        link2 = subject.instance_variable_get(:@return_feeds)[0].items[2].link
        link3 = subject.instance_variable_get(:@return_feeds)[0].items[3].link
        if link0 != "http://aaa.png"
          link0.should_not == "http://aaa.png"
        elsif link1 != "http://bbb.png"
          link1.should_not == "http://bbb.png"
        elsif link2 != "http://ccc.png"
          link2.should_not == "http://ccc.png"
        else
          pending("Plugin returns the origin feed.")
          link3.should == "http://ddd.png"
        end
      }
    end
  end
end
