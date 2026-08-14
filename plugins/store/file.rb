#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::File
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Feb 28, 2012
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

require 'fileutils'
require 'open-uri'
require 'uri'

module Automatic::Plugin
  class StoreFile

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      # The AWS SDK is required here rather than at the top of the file, so
      # that downloading over HTTP needs neither the gem nor a bucket. This
      # branch is written against AWS SDK for Ruby v1 and needs rework for the
      # current SDK; see doc/PLUGINS.md section 6.4.
      unless @config['bucket_name'].nil?
        require 'aws-sdk'
        s3 = AWS::S3.new(
          :access_key_id => @config['access_key'],
          :secret_access_key => @config['secret_key']
        )
        @bucket = s3.buckets[@config['bucket_name']]
      end
      @return_feeds = []
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            unless feed.link.nil?
              Automatic::Log.puts("info", "Downloading File: #{feed.link}")
              FileUtils.mkdir_p(@config['path']) unless FileTest.exist?(@config['path'])
              retries = 0
              retry_max = @config['retry'].to_i || 0
              begin
                retries += 1
                feed.link = get_file(feed.link)
                sleep ||= @config['interval'].to_i
                @return_feeds << feed
              rescue
                Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault during file download.")
                sleep ||= @config['interval'].to_i
                retry if retries <= retry_max
              end
            end
          }
        end
      }
      @pipeline = []
      @pipeline << Automatic::FeedMaker.create_pipeline(@return_feeds) if @return_feeds.length > 0
      @pipeline
    end

    private

    def get_file(url)
      uri = URI.parse(url)
      case uri.scheme
      when "s3n"
        return_path = get_aws(uri)
      else
        return_path = wget(uri, url)
      end
      Automatic::Log.puts("info", "Saved File: #{return_path}")
      "file://" + return_path
    end

    def wget(uri, url)
      filename = File.basename(uri.path)
      filepath = File.join(@config['path'], filename)
      URI.open(url) {|source|
        File.open(filepath, "w+b") { |o|
          o.print(source.read)
        }
      }
      filepath
    end

    def get_aws(uri)
      filename = File.basename(uri.path)
      filepath = File.join(@config['path'], filename)
      object = @bucket.objects[uri.path]
      File.open(filepath, 'wb') do |file|
        object.read do |chunk|
           file.write(chunk)
        end
      end
      filepath
    end
  end
end
