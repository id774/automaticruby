#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Console
# Author::    774 <http://id774.net>
# Created::   Feb 23, 2012
# Updated::   Feb 24, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishConsole
    require 'pp'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @output = STDOUT
    end

    def run
      @pipeline.each { |feeds|
        unless feeds.nil?
          feeds.items.each { |feed|
            @output.puts("info", feed.pretty_inspect)
          }
        end
      }
      @pipeline
    end
  end
end
