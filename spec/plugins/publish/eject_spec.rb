# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Eject
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 9, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/eject'

# PublishEject needs an optical drive and the command that drives it, which is
# the operator's machine rather than anything this suite can have. What is
# verified here is which command it would run and that the pipeline is
# returned unchanged; the drive itself is not opened.
describe Automatic::Plugin::PublishEject do
  before do
    @pipeline = AutomaticSpec.generate_pipeline {
      feed { item "http://github.com" }}
  end

  subject {
    Automatic::Plugin::PublishEject.new({ 'interval' => 0 }, @pipeline)
  }

  it "returns the pipeline unchanged" do
    subject.stub(:eject)
    subject.run.should have(1).items
  end

  it "runs the open and the close command as argument vectors" do
    subject.stub(:command_name).and_return('eject')
    subject.should_receive(:system).with('eject').ordered
    subject.should_receive(:system).with('eject', '-t').ordered
    subject.run
  end

  it "says so rather than failing where no command is installed" do
    subject.stub(:command_name).and_return(nil)
    subject.should_not_receive(:system)
    Automatic::Log.stub(:puts)
    Automatic::Log.should_receive(:puts).with('warn', /No eject command/)
    subject.run.should have(1).items
  end

  it "looks the command up on PATH" do
    subject.stub(:executable?) { |name| name == 'drutil' }
    subject.send(:command_name).should == 'drutil'
  end
end
