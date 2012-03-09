#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Ignore
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Mar  8, 2012
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
      unless @config['title'].nil?
        @config['title'].each {|e|
          if item.title.include?(e.chomp)
            detection = true 
            Automatic::Log.puts("info", "Excluded by title: #{items.link}")
          end
        }
      end
      unless @config['link'].nil?
        @config['link'].each {|e|
          if items.link.include?(e.chomp)
            detection = true 
            Automatic::Log.puts("info", "Excluded by link: #{items.link}")
          end
        }
      end
      unless @config['exclude'].nil?
        @config['exclude'].each {|e|
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
      return_feeds = []
      @pipeline.each {|feeds|
        ignore = false
        unless feeds.nil?
          feeds.items.each {|items|
            ignore = true if exclude(items)
          }
        end
        return_feeds << feeds unless ignore
      }
      return_feeds
    end
  end
end
