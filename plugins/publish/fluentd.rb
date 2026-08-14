# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Fluentd
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 21, 2013
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishFluentd
    Automatic.require_optional('fluent-logger', needed_by: 'PublishFluentd')

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @mode = @config['mode']
      @fluentd = Fluent::Logger::FluentLogger.open(nil,
        host = @config['host'],
        port = @config['port']) unless @mode == 'test'
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            begin
              @fluentd.post(@config['tag'], {
                :title => feed.title,
                :link => feed.link,
                :description => feed.description,
                :content => feed.content_encoded,
                :created_at => Time.now.strftime("%Y/%m/%d %X")
              }) unless @mode == 'test'
            rescue
              Automatic::Log.puts("warn", "Skip feed due to fault in forward.")
            end
          }
        end
      }
      @pipeline
    end
  end
end
