# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Store::File
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 28, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require 'fileutils'
require 'uri'

module Automatic::Plugin
  class StoreFile
    # A link with either scheme is fetched from S3 rather than over HTTP.
    # `s3n` is what Recipes written for this plugin use; `s3` is the spelling
    # everything else uses and is accepted as well.
    S3_SCHEMES = %w[s3 s3n].freeze

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Downloads what each link points at and rewrites the link to a file URI,
    # which is how PublishAmazonS3 later knows it has a local file.
    def run
      stored = []
      @pipeline.each do |feeds|
        next if feeds.nil?

        feeds.items.each do |feed|
          next if feed.link.nil?

          stored << feed if store(feed)
        end
      end

      @pipeline = []
      @pipeline << Automatic::FeedMaker.create_pipeline(stored) unless stored.empty?
      @pipeline
    end

    private

    def store(feed)
      Automatic::Log.puts('info', "Downloading File: #{feed.link}")
      FileUtils.mkdir_p(@config['path'].to_s)

      retries   = 0
      retry_max = @config['retry'].to_i
      begin
        feed.link = get_file(feed.link)
        sleep(@config['interval'].to_i)
        true
      rescue StandardError => e
        retries += 1
        Automatic::Log.puts('error',
                            "ErrorCount: #{retries}, Fault during file download: #{e.message}")
        return false if retries > retry_max

        sleep(@config['interval'].to_i)
        retry
      end
    end

    def get_file(url)
      uri = URI.parse(url)
      path = S3_SCHEMES.include?(uri.scheme) ? from_s3(uri) : download(url)
      Automatic::Log.puts('info', "Saved File: #{path}")
      "file://#{path}"
    end

    # Only HTTP and HTTPS are fetched: a link arrives from a feed, which is to
    # say from outside, and `file://` is not something a store plugin should
    # be talked into reading.
    def download(url)
      path = local_path(Automatic::Http.uri(url).path)
      File.binwrite(path, Automatic::Http.read(url))
      path
    end

    # AWS SDK for Ruby v3, one gem for one service. The bucket is the Recipe's
    # `bucket_name` where it has one, so that an existing Recipe keeps its
    # meaning, and the link's own host otherwise. Credentials are the Recipe's
    # where it carries them and the SDK's default chain -- environment,
    # profile, instance role -- where it does not, which is the way to run
    # this without a secret in a file.
    def from_s3(uri)
      path = local_path(uri.path)
      s3.get_object(bucket: bucket(uri), key: uri.path.sub(%r{\A/}, ''),
                    response_target: path)
      path
    end

    def s3
      @s3 ||= begin
        Automatic.require_optional('aws-sdk-s3', needed_by: 'the S3 path of StoreFile')
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

    def bucket(uri)
      name = @config['bucket_name'].to_s
      name.empty? ? uri.host.to_s : name
    end

    def local_path(remote_path)
      name = File.basename(remote_path.to_s)
      raise ArgumentError, "no file name in #{remote_path}" if name.empty? || name == '/'

      File.join(@config['path'].to_s, name)
    end
  end
end
