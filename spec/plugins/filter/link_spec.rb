# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Link
# Author::    774 <http://id774.net>
# Created::   Jun 12, 2012
# Updated::   Jun 12, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/link'

describe Automatic::Plugin::FilterLink do
  context "with html contain link tag" do
    subject {
      Automatic::Plugin::FilterLink.new({},
        AutomaticSpec.generate_pipeline {
          html "filterLink.html"
        }
      )}

    describe "#run" do
      its(:run) { should have(1).feeds }
      specify {
        subject.run
        except = "http://id774.net"
        subject.instance_variable_get(:@return_html)[0].should == except
      }
    end
  end
end

