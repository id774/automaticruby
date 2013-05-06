# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Rand
# Author::    soramugi <http://soramugi.net>
# Created::   May  6, 2013
# Updated::   May  6, 2013
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
            item "http://eee.png"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        link0 = subject.instance_variable_get(:@return_feeds)[0].items[0].link
        if link0 != "http://aaa.png"
          link0.should_not == "http://aaa.png"
        else
          link1 = subject.instance_variable_get(:@return_feeds)[0].items[1].link
          link1.should_not == "http://bbb.png"
        end
      }
    end
  end
end
