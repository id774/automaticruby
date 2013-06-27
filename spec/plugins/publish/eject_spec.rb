# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Eject
# Author::    soramugi <http://soramugi.net>
# Created::   Jun 9, 2013
# Updated::   Jun 9, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/eject'

describe Automatic::Plugin::PublishEject do
  before do
    @pipeline = AutomaticSpec.generate_pipeline {
      feed { item "http://github.com" }}
  end

  subject {
    Automatic::Plugin::PublishEject.new({}, @pipeline)
  }

  it "should eject of feeds" do
    subject.stub(:eject_cmd).and_return('echo')
    subject.run.should have(1).items
  end

  subject {
    Automatic::Plugin::PublishEject.new({'interval' => 0}, @pipeline)
  }

  it "should eject of feeds" do
    subject.stub(:eject_cmd).and_return('echo')
    subject.run.should have(1).items
  end

  it "should eject_cmd" do
    subject.eject_cmd.should_not == ''
  end
end
