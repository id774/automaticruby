#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

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

  def bookmark
    @pipeline.each {|links|
      links.each {|link|
        Log.puts("info", "Bookmarking: #{link}")
        new_bookmark = Bookmark.new(:url => link,
          :created_at => Time.now.strftime("%Y/%m/%d %X"))
        new_bookmark.save
        hb.post(link, nil)
        sleep 5
      }
    }
  end

  def run
    bookmark
  end
end
