# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::ConsoleLink
# Author::    soramugi <http://soramugi.net>
# Created::   Jun 02, 2013
# Updated::   Jun 02, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishConsoleLink
    require 'pp'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @output = STDOUT
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            @output.puts("info", feed.link)
          }
        end
      }
      @pipeline
    end
  end
end
