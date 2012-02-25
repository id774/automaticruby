# -*- coding: utf-8 -*-
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
    context "Today's event to some place" do
      specify {
        GoogleCalendar::Calendar.stub(:new) {
          cal = mock("cal")
          cal.should_receive(:create_event).and_return {
            event = mock("event")
            {
              :title => "お出かけ",
              :where => "池袋",
              :st => nil,
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
            event
          }
          cal
        }
        Automatic::Plugin::Googlecalendar.new.add("今日お出かけ＠池袋")
      }
    end
  end
end
