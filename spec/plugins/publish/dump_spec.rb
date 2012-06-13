# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Dump
# Author::    774 <http://id774.net>
# Created::   Jun 13, 2012
# Updated::   Jun 13, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.
#
require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/dump'

describe Automatic::Plugin::PublishDump do

  context "with contain normal HTML" do
    subject {
      Automatic::Plugin::PublishDump.new({},
        AutomaticSpec.generate_pipeline {
          html "publishDump.html"
        }
      )}

    describe "#run" do
      its(:run) { should have(1).feeds }
      specify {
        subject.run
        expect = "<!DOCTYPE html>\n<html lang=\"ja\">\n  <head>\n    <title>Sample</title>\n  </head>\n  <body>\n    <p>A simple <b>test</b> string.</p>\n    <a href=\"http://id774.net\">id774.net</a>\n    <a href=\"http://reblog.id774.net\">reblog.id774.net</a>\n    <a href=\"http://oh-news.net/live/wp-content/uploads/2011/04/Eila_omote.jpg\">\n      <img src=\"http://24.media.tumblr.com/tumblr_m5gneyJmsH1qza5ppo1_500.jpg\" alt=\"\" /></a>\n    <a href=\"http://blog.id774.net/post/\">blog.id774.net</a>\n  </body>\n</html>\n"
        subject.instance_variable_get(:@pipeline)[0].should == expect
      }
    end
  end
end
