# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Console
# Author::    774 <http://id774.net>
# Updated::   Feb 25, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/console'

describe Automatic::Plugin::PublishConsole do
  before do
    @pipeline = AutomaticSpec.generate_pipeline {
      feed { item "http://github.com" }
    }
  end

  subject {
    Automatic::Plugin::PublishConsole.new({}, @pipeline)
  }

  it "should output pretty inspect of feeds" do
    output = double("output")
    output.should_receive(:puts).
      with("info", @pipeline[0].items[0].pretty_inspect)
    subject.instance_variable_set(:@output, output)
    subject.run.should have(1).items
  end
end
