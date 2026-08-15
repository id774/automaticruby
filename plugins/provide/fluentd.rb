# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Provide::Fluentd
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jul 12, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class ProvideFluentd
    Automatic.require_optional('fluent-logger', needed_by: 'ProvideFluentd')

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @mode     = @config['mode']
      @fluentd  = open_logger unless test?
    end

    # Posts each item's content_encoded to Fluentd, which must be something
    # Fluentd accepts as a record. Distinct from PublishFluentd, which posts
    # the item's fields.
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

      @fluentd.post(@config['tag'], feed.content_encoded)
    rescue StandardError => e
      Automatic::Log.puts('error',
                          'Fluent::Logger.post failed, the content_encoded of item may ' \
                          "be not kind of Hash: #{e.message}")
    end

    def test?
      @mode == 'test'
    end
  end
end
