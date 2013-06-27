# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Fluentd
# Author::    774 <http://id774.net>
# Created::   Jun 21, 2013
# Updated::   Jun 25, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishFluentd
    require 'fluent-logger'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @fluentd = Fluent::Logger::FluentLogger.open(nil,
        host = @config['host'],
        port = @config['port'])
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
              })
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
