#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::TargetLink
# Author::    774 <http://id774.net>
# Created::   Feb 28, 2012
# Updated::   Feb  9, 2013
# Copyright:: 774 Copyright (c) 2012-2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'open-uri'

module Automatic::Plugin
  class StoreTargetLink

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            unless feed.link.nil?
              Automatic::Log.puts("info", "Downloading: #{feed.link}")
              retries = 0
              begin
                retries += 1
                wget(feed.link)
                sleep @config['interval'].to_i unless @config['interval'].nil?
              rescue
                Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault during file download.")
                sleep @config['interval'].to_i unless @config['interval'].nil?
                retry if retries <= @config['retry'].to_i unless @config['retry'].nil?
              end
            end
          }
        end
      }
      @pipeline
    end

    private
    def wget(url)
      filename = url.split(/\//).last
      open(url) { |source|
        open(File.join(@config['path'], filename), "w+b") { |o|
          o.print source.read
        }
      }
    end
  end
end
