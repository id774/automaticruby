# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Ignore
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterIgnore
    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        new_feeds = []
        unless feeds.nil?
          feeds.items.each {|items|
            new_feeds << items if exclude(items) == false
          }
        end
        @return_feeds << Automatic::FeedMaker.create_pipeline(new_feeds) if new_feeds.length > 0
      }
      @return_feeds
    end

    private
    def detect_exclude(item, evaluation, reason)
      begin
        if item.include?(evaluation)
          Automatic::Log.puts("info", "Excluded by #{reason}: #{item}")
          return true
        end
      rescue NoMethodError
        Automatic::Log.puts("warn", "Invalid feed detected in ignore process with #{item}")
        return false
      end
    end

    def exclude(items)
      detection = false
      unless @config['title'].nil?
        @config['title'].each {|e|
          detection = true if detect_exclude(items.title, e.chomp, 'title')
        }
      end
      unless @config['link'].nil?
        @config['link'].each {|e|
          detection = true if detect_exclude(items.link, e.chomp, 'link')
        }
      end
      unless @config['description'].nil?
        @config['description'].each {|e|
          detection = true if detect_exclude(items.description, e.chomp, 'description')
        }
      end
      detection
    end
  end
end
