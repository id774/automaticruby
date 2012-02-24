#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Googlecalendar
# Author::    774 <http://id774.net>
# Created::   Feb 24, 2012
# Updated::   Feb 24, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

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
    weekdays = [ '日', '月', '火', '水', '木', '金', '土' ]
    date     = nil
    time_st  = nil
    time_en  = nil
    text     = ''
    location = ''

    # Parse Date
    require 'date'
    today = Date.today
    case arg
    when /^今日\s*/
      date = today
      text = $'
    when /^(明日|あした|あす)\s*/
      date = today + 1
      text = $'
    when /^(明後日|あさって)\s*/
      date = today + 2
      text = $'
    when /^(日|月|火|水|木|金|土)曜(日)?\s*/
      date_offset = (weekdays.index($1) - today.wday + 7) % 7
      date_offset += 7 if date_offset == 0
      date = today + date_offset
      text = $'
    when /^([0-9]+\/[0-9]+\/[0-9]+)\s*/
      # yyyy/mm/dd
      datestr = $1
      text    = $'
      begin
        date = Date.parse(datestr)
      rescue ArgumentError
        puts "不正な日付形式-1： [#{datestr}]"
        exit
      end
    when /^([0-9]+\/[0-9]+)\s*/
      # mm/dd
      datestr = $1
      text    = $'
      begin
        date = Date.parse(datestr)
      rescue ArgumentError
        puts "不正な日付形式-2： [#{datestr}]"
        exit
      end
      while date < today
        date = date >> 12
      end
    when /^([0-9]+)\s*/
      datestr = $1
      text    = $'
      case datestr.length
      when 2
        datestr = datestr.slice(0..0) + "/" + datestr.slice(1..1)
      when 3
        datestr = datestr.slice(0..0) + "/" + datestr.slice(1..2)
      when 4
        datestr = datestr.slice(0..1) + "/" + datestr.slice(2..3)
      else
        puts "不正な日付形式-3： [#{datestr}]"
        exit
      end
      begin
        date = Date.parse(datestr)
      rescue ArgumentError
        puts "不正な日付形式-4： [#{datestr}]"
        exit
      end
      while date < today
        date = date >> 12
      end
    end

    # Parse Time
    require 'time'
    begin
      case text
      when /^([0-9]+):([0-9]+)-([0-9]+):([0-9]+)\s*/
        time_st = Time.mktime(date.year, date.month, date.day, $1.to_i, $2.to_i, 0, 0)
        time_en = Time.mktime(date.year, date.month, date.day, $3.to_i, $4.to_i, 0, 0)
        text = $'
      when /^([0-9]+):([0-9]+)\s*/
        time_st = Time.mktime(date.year, date.month, date.day, $1.to_i, $2.to_i, 0, 0)
        time_en = time_st + 3600
        text = $'
      end
    rescue ArgumentError
      puts "時刻が範囲外？： #{text}"
      exit
    end

    # Parse Location
    if text =~ /＠/
      text     = $`
      location = $'
    end

    puts "日付     ： #{date}"
    puts "開始時刻 ： #{time_st}"
    puts "開始時刻 ： #{time_en}"
    puts "タイトル ： #{text}"
    puts "場所     ： #{location}"

    # Register to calendar
    require 'rubygems'
    require 'gcalapi'

    cal = GoogleCalendar::Calendar.new(GoogleCalendar::Service.new(@user["username"], @user["password"]), @feed)

    if time_st && time_en
      event       = cal.create_event
      event.title = text
      event.where = location
      event.st    = time_st
      event.en    = time_en
      event.save!
    else
      # All day
      event       = cal.create_event
      event.title = text
      event.where = location
      event.st    = Time.mktime(date.year, date.month, date.day)
      event.en    = event.st
      event.allday = true
      event.save!
    end
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
          sleep @config['interval'].to_i
        }
      end
    }
    @pipeline
  end
end

if __FILE__ == $0
  abort("Usage: google_calendar.rb <date> <time> <plan>") if ARGV.size == 0
  gc = Googlecalendar.new
  gc.add(ARGV.join(' '))
end
