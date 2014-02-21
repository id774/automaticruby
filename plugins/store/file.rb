#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::File
# Author::    774 <http://id774.net>
# Created::   Feb 28, 2012
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'open-uri'

module Automatic::Plugin
  class StoreFile

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @return_feeds = []
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
                feed.link = wget(feed.link)
                sleep ||= @config['interval'].to_i
                @return_feeds << Automatic::FeedMaker.generate_feed(feed)
              rescue
                Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault during file download.")
                sleep ||= @config['interval'].to_i
                retry if retries <= retry_max
              end
            end
          }
        end
      }
      @pipeline << Automatic::FeedMaker.create_pipeline(@return_feeds) if @return_feeds.length > 0
      @pipeline
    end

    private
    def wget(url)
      filename = url.split(/\//).last
      filepath = File.join(@config['path'], filename)
      open(url) {|source|
        open(filepath, "w+b") { |o|
          o.print source.read
        }
      }
      uri_scheme = "file://" + filepath
      Automatic::Log.puts("info", "Saved: #{uri_scheme}")
      uri_scheme
    end
  end
end
