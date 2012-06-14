# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Console
# Author::    774 <http://id774.net>
# Updated::   Jun 14, 2012
# Copyright:: 774 Copyright (c) 2012
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
    output = mock("output")
    output.should_receive(:puts).
      with("info", @pipeline[0].items[0].pretty_inspect)
    subject.instance_variable_set(:@output, output)
    subject.run.should have(1).items
  end
end
