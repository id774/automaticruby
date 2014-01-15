#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::TargetLink
# Author::    774 <http://id774.net>
# Created::   Feb 28, 2012
# Updated::   Jan 15, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
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
              FileUtils.mkdir_p(@config['path']) unless FileTest.exist?(@config['path'])
              retries = 0
              retry_max = @config['retry'].to_i || 0
              begin
                retries += 1
                wget(feed.link)
                sleep ||= @config['interval'].to_i
              rescue
                Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault during file download.")
                sleep ||= @config['interval'].to_i
                retry if retries <= retry_max
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
      open(url) {|source|
        open(File.join(@config['path'], filename), "w+b") { |o|
          o.print source.read
        }
      }
    end
  end
end
