#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::TargetLink
# Author::    774 <http://id774.net>
# Created::   Feb 28, 2012
# Updated::   Mar  1, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class StoreTargetLink
    require 'open-uri'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def wget(url)
      filename = url.split(/\//).last
      open(url) { |source|
        open(File.join(@config['path'], filename), "w+b") { |o|
          o.print source.read
        }
      }
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            begin
              unless feed.link.nil?
                Automatic::Log.puts("info", "Get: #{feed.link}")
                wget(feed.link)
                sleep @config['interval'].to_i
              end
            rescue
              Automatic::Log.puts("error", "Error found during file download.")
            end
          }
        end
      }
      @pipeline
    end
  end
end
