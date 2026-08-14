# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Provide::Fluentd
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Jul 12, 2013
# Updated::   May 16, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.

module Automatic::Plugin
  class ProvideFluentd
    require 'fluent-logger'

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
              @fluentd.post(@config['tag'], feed.content_encoded) unless @mode == 'test'
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
