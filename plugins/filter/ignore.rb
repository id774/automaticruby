#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Ignore
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 22, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

class FilterIgnore
  def initialize(config, pipeline=[])
    @config = config
    @pipeline = pipeline
  end

  def exclude(link)
    detection = false
    @config['exclude'].each {|e|
      detection = true if link.include?(e.chomp)
    }
    if detection
      Log.puts("info", "Excluded: #{link}")
    end
    detection
  end

  def run
    return_feeds = []
    @pipeline.each {|feeds|
      ignore = false
      unless feeds.nil?
        feeds.items.each {|feed|
          ignore = true if exclude(feed.link)
        }
      end
      return_feeds << feeds unless ignore
    }
    return_feeds
  end
end
