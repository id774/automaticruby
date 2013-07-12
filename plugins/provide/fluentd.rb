# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Provide::Fluentd
# Author::    774 <http://id774.net>
# Created::   Jul 12, 2013
# Updated::   Jul 12, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class ProvideFluentd
    require 'fluent-logger'
    require 'active_support'

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
              @fluentd.post(@config['tag'], feed.content_encoded)
            rescue
              Automatic::Log.puts("error", "Fluent::Logger.post failed, the content_encoded of item may be not kind of Hash.")
            end
          }
        end
      }
      @pipeline
    end
  end
end
