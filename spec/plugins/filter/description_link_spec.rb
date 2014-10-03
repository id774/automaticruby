# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::DescriptionLink
# Author::    774 <http://id774.net>
# Created::   Oct 03, 2014
# Updated::   Oct 03, 2014
# Copyright:: Copyright (c) 2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/description_link'

describe Automatic::Plugin::FilterDescriptionLink do

  context "It should be rewrite link based on the description" do

    subject {
      Automatic::Plugin::FilterDescriptionLink.new(
        {},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://test1.id774.net",
            "dummy title",
            "aaa bbb ccc http://test2.id774.net",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://test2.id774.net"
      }
    end
  end

end
