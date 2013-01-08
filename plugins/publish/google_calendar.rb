# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Googlecalendar
# Author::    774 <http://id774.net>
# Created::   Feb 24, 2012
# Updated::   Jan  8, 2013
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

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

      puts "日付     ： #{date}"
      puts "タイトル ： #{text}"

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
            sleep @config['interval'].to_i unless @config['interval'].nil?
          }
        end
      }
      @pipeline
    end
  end
end
