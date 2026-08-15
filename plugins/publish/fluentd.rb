# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Fluentd
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 21, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishFluentd
    Automatic.require_optional('fluent-logger', needed_by: 'PublishFluentd')

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @mode     = @config['mode']
      @fluentd  = open_logger unless test?
    end

    # Posts each item's title, link, description, content_encoded and a
    # timestamp to Fluentd.
    def run
      @pipeline.each do |feeds|
        next if feeds.nil?

        feeds.items.each { |feed| post(feed) }
      end
      @pipeline
    end

    private

    def open_logger
      Fluent::Logger::FluentLogger.open(nil,
                                        host: @config['host'],
                                        port: @config['port'].to_i)
    end

    def post(feed)
      return if test?

      @fluentd.post(@config['tag'], record(feed))
    rescue StandardError => e
      Automatic::Log.puts('warn', "Skip feed due to fault in forward: #{e.message}")
    end

    def record(feed)
      {
        title: feed.title,
        link: feed.link,
        description: feed.description,
        content: feed.content_encoded,
        created_at: Time.now.strftime('%Y/%m/%d %X')
      }
    end

    def test?
      @mode == 'test'
    end
  end
end
