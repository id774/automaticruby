# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Googlecalendar
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 24, 2012
# Updated::     Jan 15, 2014
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class Googlecalendar
    attr_accessor :user, :feed

    def initialize
      @user = {
        "username" => "",
        "password" => ""
      }
      @feed = 'http://www.google.com/calendar/feeds/default/private/full'
    end

    def add(arg)
      date     = nil
      time_st  = nil
      time_en  = nil
      text     = ''

      # Parse Date
      require 'date'
      if /^([0-9]+\/[0-9]+\/[0-9]+)\s*/ =~ arg
        # yyyy/mm/dd
        datestr = $1
        text    = $'
        begin
          date = Date.parse(datestr)
        rescue ArgumentError
          raise "不正な日付形式-1： [#{datestr}]"
        end
      end

      Automatic::Log.puts("info", "Date  ： #{date}")
      Automatic::Log.puts("info", "Title ： #{text}")

      # Register to calendar
      require 'rubygems'
      require 'gcalapi'

      cal = GoogleCalendar::Calendar.new(GoogleCalendar::Service.new(
          @user["username"], @user["password"]), @feed)
      event       = cal.create_event
      event.title = text
      event.st    = Time.mktime(date.year, date.month, date.day)
      event.en    = event.st
      event.allday = true
      event.save!
    end
  end

  class PublishGoogleCalendar
    attr_accessor :hb

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline

      @gc = Googlecalendar.new
      @gc.user = {
        "hatena_id" => @config['username'],
        "password"  => @config['password']
      }
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            @gc.add('今日 ' + feed.title)
            sleep ||= @config['interval'].to_i
          }
        end
      }
      @pipeline
    end
  end
end
