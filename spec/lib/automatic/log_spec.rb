# -*- coding: utf-8 -*-
# Name::      Auaotmatic::Log
# Author::    soramugi
# Created::   May 19, 2013
# Updated::   May 19, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.join(File.dirname(__FILE__) ,'../../spec_helper'))
require 'automatic'
require 'automatic/log'

describe Automatic::Log do
  ['info', 'warn', 'error'].each {|level|
    describe "with a #{level} log" do
      it "puts" do
        Automatic::Log.level('info')
        Automatic::Log.puts(level, 'log spec').should_not == nil
      end

      if 'info' != level
        it "not puts" do
          Automatic::Log.level(level)
          Automatic::Log.puts('info', 'log spec').should == nil
        end
      end
    end
  }
end
