# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Eject
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Jun 9, 2013
# Updated::   Jun 9, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.

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
