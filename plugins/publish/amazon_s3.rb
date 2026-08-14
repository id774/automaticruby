# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::AmazonS3
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 24, 2014
# Updated::     Feb 24, 2014
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishAmazonS3
    require 'uri'
    require 'aws-sdk'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      s3 = AWS::S3.new(
        :access_key_id => @config['access_key'],
        :secret_access_key => @config['secret_key']
      )
      @bucket = s3.buckets[@config['bucket_name']]
      @mode = @config['mode']
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            unless feed.link.nil?
              begin
                uri = URI.parse(feed.link)
                if uri.scheme == 'file'
                  upload_amazons3(uri.path, @config['target_path'])
                else
                  Automatic::Log.puts("warn", "Skip feed due to uri scheme is not file.")
                end
              rescue
                Automatic::Log.puts("error", "Error detected with #{feed.link} in uploading AmazonS3.")
              end
            end
          }
        end
      }
      @pipeline
    end

    private

    def upload_amazons3(filename, target_path)
      target = File.join(target_path, File.basename(filename))
      object = @bucket.objects[target]
      source = Pathname.new(filename)
      object.write(source) unless @mode == "test"
      Automatic::Log.puts("info", "Uploaded: file #{source} to the bucket #{target} on #{@bucket.name}.")
      return source, target
    end
  end
end
