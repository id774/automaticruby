# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::ConsoleLink
# Author::    soramugi <http://soramugi.net>
# Created::   Jun 02, 2013
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishConsoleLink
    require 'pp'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @output = $stdout
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            @output.puts(feed.link)
          }
        end
      }
      @pipeline
    end
  end
end
