# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Console
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 25, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

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
      with(@pipeline[0].items[0].pretty_inspect)
    subject.instance_variable_set(:@output, output)
    subject.run.should have(1).items
  end
end
