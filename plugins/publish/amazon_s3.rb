# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::AmazonS3
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 24, 2014
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishAmazonS3
    require 'uri'

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @mode     = @config['mode']
    end

    # Uploads the files whose link is a file URI, normally after StoreFile.
    def run
      @pipeline.each do |feeds|
        next if feeds.nil?

        feeds.items.each { |feed| publish(feed) }
      end
      @pipeline
    end

    private

    def publish(feed)
      return if feed.link.nil?

      uri = URI.parse(feed.link)
      if uri.scheme == 'file'
        upload(uri.path)
      else
        Automatic::Log.puts('warn', 'Skip feed due to uri scheme is not file.')
      end
    rescue StandardError => e
      Automatic::Log.puts('error',
                          "Error detected with #{feed.link} in uploading AmazonS3: #{e.message}")
    end

    def upload(path)
      key = target_key(path)
      File.open(path, 'rb') { |body| s3.put_object(bucket: bucket, key: key, body: body) } unless test?
      Automatic::Log.puts('info', "Uploaded: file #{path} to the key #{key} on #{bucket}.")
      [path, key]
    end

    def target_key(path)
      File.join(@config['target_path'].to_s, File.basename(path)).sub(%r{\A/}, '')
    end

    def bucket
      @config['bucket_name'].to_s
    end

    def test?
      @mode == 'test'
    end

    # AWS SDK for Ruby v3, which is the SDK AWS publishes and maintains. The
    # gem is required here rather than at the top of the file, so that a
    # Recipe running this plugin in `mode: test` -- and this plugin's own
    # specs -- need neither the gem nor an account.
    #
    # Credentials are the Recipe's where it carries them, and the SDK's
    # default chain -- environment, shared profile, instance role -- where it
    # does not, which is the way to run this without a secret in a file.
    def s3
      @s3 ||= begin
        Automatic.require_optional('aws-sdk-s3', needed_by: 'PublishAmazonS3')
        Aws::S3::Client.new(**client_options)
      end
    end

    def client_options
      options = {}
      options[:region] = @config['region'].to_s unless @config['region'].nil?
      unless @config['access_key'].nil?
        options[:access_key_id]     = @config['access_key'].to_s
        options[:secret_access_key] = @config['secret_key'].to_s
      end
      options
    end
  end
end
