#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::HatenaBookmark
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 22, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

class PublishHatenaBookmark
  attr_accessor :hb

  def initialize(config, pipeline=[])
    @config = config
    @pipeline = pipeline

    @hb = HatenaBookmark.new
    @hb.user = {
      "hatena_id" => @config['username'],
      "password"  => @config['password']
    }
  end

  def run
    @pipeline.each {|feeds|
      unless feeds.nil?
        feeds.items.each {|feed|
          Log.puts("info", "Bookmarking: #{feed.link}")
          new_bookmark = Bookmark.new(:url => feed.link,
            :created_at => Time.now.strftime("%Y/%m/%d %X"))
          new_bookmark.save
          hb.post(feed.link, nil)
          sleep 5
        }
      end
    }
    @pipeline
  end
end
