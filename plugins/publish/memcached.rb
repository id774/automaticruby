# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Memcached
# Author::    774 <http://id774.net>
# Created::   Jun 25, 2013
# Updated::   Jun 25, 2013
# Copyright:: 774 Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishMemcached
    require 'dalli'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @cache = Dalli::Client.new(
        @config['host'] + ":" +
        @config['port'])
    end

    def run
      hash = {}
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            hash[feed.link] =
              {
                :title => feed.title,
                :description => feed.description,
                :content => feed.content_encoded,
                :created_at => Time.now.strftime("%Y/%m/%d %X")
              }
          }
        end
      }
      begin
        @cache.set(@config['key'], hash)
      rescue
        Automatic::Log.puts("warn", "Skip feed due to fault in put to memcached.")
      end
      @pipeline
    end
  end
end
