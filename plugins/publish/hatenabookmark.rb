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
    @pipeline
  end
end
