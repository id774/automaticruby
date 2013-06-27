# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::One
# Author::    soramugi <http://soramugi.net>
# Created::   May  8, 2013
# Updated::   May  8, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/one'

describe Automatic::Plugin::FilterOne do
  context "It should be one" do
    subject {
      Automatic::Plugin::FilterOne.new(
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
        subject.instance_variable_get(:@return_feeds)[0].items.
          count.should == 1
        subject.instance_variable_get(:@return_feeds)[0].items[0].link.
          should == 'http://aaa.png'
      }
    end
  end

  context "It should be one last" do
    subject {
      Automatic::Plugin::FilterOne.new(
        {
          'pick' => "last"
        },
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
        subject.instance_variable_get(:@return_feeds)[0].items.
          count.should == 1
        subject.instance_variable_get(:@return_feeds)[0].items[0].link.
          should == 'http://ddd.png'
      }
    end
  end
end
