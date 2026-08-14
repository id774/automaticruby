# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Instapaper
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 9,  2013
# Updated::     Feb 25, 2014
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/instapaper'

describe Automatic::Plugin::PublishInstapaper do
  context 'when feed' do
    subject {
      Automatic::Plugin::PublishInstapaper.new(
        { 'email' => "email@example.com",
          'password' => "pswd",
          'interval' => 5,
          'retry' => 5
    },
      AutomaticSpec.generate_pipeline {
      feed { item "http://github.com" }
    })}

    it "should post the link in the feed" do
      instapaper = double("instapaper")
      instapaper.should_receive(:add).with("http://github.com", nil, '')
      subject.instance_variable_set(:@instapaper, instapaper)
      subject.run.should have(1).feed
    end
  end

  context 'when feed is empty' do
    subject {
      Automatic::Plugin::PublishInstapaper.new(
        { 'email' => "email@example.com",
          'password' => "pswd",
          'interval' => 1,
          'retry' => 1
    },
      AutomaticSpec.generate_pipeline {
      feed { item "http://github.com" }
    })}

    its (:run) { subject.run.should have(1).feed }
  end
end

describe Automatic::Plugin::Instapaper do
  describe "#add" do
    subject {
      Automatic::Plugin::Instapaper.new(
        { 'email' => "email@example.com",
          'password' => "pswd",
          'interval' => 5,
          'retry' => 5
    })}

    url         = "http://www.google.com"
    title       = "automatic test"
    description = "automatic test"

    specify {
      res = double("res")
      res.should_receive(:code).and_return("201")
      subject.should_receive(:request).and_return(res)
      subject.add(url, title, description)
    }


    it 'raise error' do
      lambda{
        res = double("res")
        res.should_receive(:code).twice.and_return("403")
        subject.should_receive(:request).and_return(res)
        subject.add(url, title, description)
      }.should raise_error
    end
  end
end
