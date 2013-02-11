# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Ignore
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 13, 2013
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterIgnore
    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def exclude(items)
      detection = false
      unless @config['link'].nil?
        @config['link'].each {|e|
          if items.link.include?(e.chomp)
            detection = true
            Automatic::Log.puts("info", "Excluded by link: #{items.link}")
          end
        }
      end
      unless @config['description'].nil?
        @config['description'].each {|e|
          if items.description.include?(e.chomp)
            detection = true
            Automatic::Log.puts("info", "Excluded by description: #{items.link}")
          end
        }
      end
      detection
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
        @return_feeds << Automatic::FeedParser.create(new_feeds) if new_feeds.length > 0
      }
      @return_feeds
    end
  end
end
