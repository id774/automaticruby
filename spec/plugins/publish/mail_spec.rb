# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Mail
# Author::    774 <http://id774.net>
# Updated::   Jun 14, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/mail'
require 'mocksmtpd'

describe Automatic::Plugin::PublishMail do
  before do
    @pipeline = AutomaticSpec.generate_pipeline {
      feed { item "http://github.com",
          'aaa',
          'bbb\n',
          'Mon, 30 Jan 2012 13:22:29 +0900'
      }
    }
  end

  subject {
    Automatic::Plugin::PublishMail.new({
        "port" => 25,
        "mailto" => "<to@example.com>",
        "mailfrom" => "<from@example.com>",
        "subject" => "test"
      }, @pipeline)
  }

  it "should mail to smtp server" do
    smtpd = SMTPServer.new({
        :Port => 10025,
        :MailHook => lambda { |sender| sender.should == "<from@example.com>" },
        :DataHook => lambda { |tmpf, sender, recipients|
          tmpf.should include("github.com")
          sender.should == "<from@example.com>"
          recipients.should == ["<to@example.com>"]
        }
      }
    )
    Thread.start {
      smtpd.start
    }
    loop do
      break if smtpd.status == :Running
    end
    subject.run
    smtpd.shutdown
  end
end
