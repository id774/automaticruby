# -*- coding: utf-8 -*-
# Name::      Auaotmatic::Log
# Author::    soramugi
#             774 <http://id774.net>
# Created::   May 19, 2013
# Updated::   Oct 09, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.join(File.dirname(__FILE__) ,'../../spec_helper'))
require 'automatic'
require 'automatic/log'

describe Automatic::Log do
  context "with a puts" do
    ['info', 'warn', 'error'].each {|level|
      its (level) {
        subject.level(level)
        subject.puts(level, 'log spec').should_not == nil
      }
    }
  end

  context "with a not puts" do
    ['warn', 'error', 'none'].each {|level|
      its (level) {
        subject.level(level)
        subject.puts('info', 'log spec').should == nil
      }
    }
  end
end
