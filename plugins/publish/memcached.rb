# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Memcached
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 25, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishMemcached
    Automatic.require_optional('dalli', needed_by: 'PublishMemcached')

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      # Interpolated rather than concatenated: `port: 11211` in a Recipe is an
      # Integer, and String#+ ended the run on it.
      @cache    = Dalli::Client.new("#{@config['host']}:#{@config['port']}")
    end

    # Collects the whole pipeline into one hash keyed by link and stores it
    # under a single key, replacing the previous value.
    def run
      @cache.set(@config['key'], collect)
      @pipeline
    rescue StandardError => e
      Automatic::Log.puts('warn', "Skip feed due to fault in put to memcached: #{e.message}")
      @pipeline
    end

    private

    def collect
      @pipeline.each_with_object({}) do |feeds, hash|
        next if feeds.nil?

        feeds.items.each do |feed|
          hash[feed.link] = {
            title: feed.title,
            description: feed.description,
            content: feed.content_encoded,
            created_at: Time.now.strftime('%Y/%m/%d %X')
          }
        end
      end
    end
  end
end
