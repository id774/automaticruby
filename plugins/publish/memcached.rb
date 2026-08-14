# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Memcached
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Jun 25, 2013
# Updated::   Jun 25, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.

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
