# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Accept
# Author::    soramugi <http://soramugi.net>
# Created::   Jun  4, 2013
# Updated::   Jun  4, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterAccept
    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        new_feeds = []
        unless feeds.nil?
          feeds.items.each {|items|
            new_feeds << items if contain(items) == true
          }
        end
        @return_feeds << Automatic::FeedParser.create(new_feeds) if new_feeds.length > 0
      }
      @return_feeds
    end

    private

    def contain(items)
      detection = false
      unless @config['title'].nil?
        @config['title'].each {|e|
          if items.title.include?(e.chomp)
            detection = true
            Automatic::Log.puts("info", "Contain by title: #{items.link}")
          end
        }
      end
      unless @config['link'].nil?
        @config['link'].each {|e|
          if items.link.include?(e.chomp)
            detection = true
            Automatic::Log.puts("info", "Contain by link: #{items.link}")
          end
        }
      end
      unless @config['description'].nil?
        @config['description'].each {|e|
          if items.description.include?(e.chomp)
            detection = true
            Automatic::Log.puts("info", "Contain by description: #{items.link}")
          end
        }
      end
      detection
    end
  end
end
