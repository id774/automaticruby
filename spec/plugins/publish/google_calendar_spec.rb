# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::CustomFeed::SVNFLog
# Author::    kzgs
# Created::   Feb 26, 2012
# Updated::   Mar 3, 2012
# Copyright:: kzgs Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/google_calendar'
require 'gcalapi'

describe Automatic::Plugin::PublishGoogleCalendar do
  subject {
    Automatic::Plugin::PublishGoogleCalendar.new(
      {"username" => "user", "password" => "pswd"},
      AutomaticSpec.generate_pipeline{
        feed {
          item "http://github.com", "GitHub"
        }
      })
  }

  it "should post the link in the feed" do
    gc = mock("gc")
    gc.should_receive(:add).with("今日 GitHub")
    subject.instance_variable_set(:@gc, gc)
    subject.run.should have(1).feed
  end
end

describe Automatic::Plugin::Googlecalendar do
  describe "#add" do
    context "All day events" do
      specify {
        set_gcal_mock(all_day_event_mock(
            "花火＠晴海", "", Time.mktime(2012, 8, 15)))
        Automatic::Plugin::Googlecalendar.new.add("2012/8/15 花火＠晴海")
      }

      specify {
        lambda {
          Automatic::Plugin::Googlecalendar.new.add("2012/2/30")
        }.should raise_exception(RuntimeError, /不正な日付形式-1/)
      }
    end
  end
end

def all_day_event_mock(title, where, date=nil)
  event = mock("event")
  {
    :title => title,
    :st => date.nil? ? nil : Time.mktime(date.year, date.month, date.day),
    :en => nil,
    :allday => true
  }.each_pair do |key, value|
    if value.nil?
      event.should_receive("#{key}=".to_sym)
    else
      event.should_receive("#{key}=".to_sym).with(value)
    end
  end
  event.should_receive(:st)
  event.should_receive(:save!)
  return event
end

def cal_mock(event_mock)
  cal = mock("cal")
  cal.should_receive(:create_event).and_return {
    event_mock
  }
  return cal
end

def set_gcal_mock(event_mock)
  GoogleCalendar::Calendar.stub(:new) {
    cal_mock(event_mock)
  }
end
