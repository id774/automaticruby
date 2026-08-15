# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Instapaper
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb  9, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  # The Instapaper Simple API: HTTPS, basic authentication, form parameters.
  # @see https://www.instapaper.com/api/simple
  class Instapaper
    require 'net/http'
    require 'openssl'
    require 'uri'

    HOST = 'www.instapaper.com'
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30

    class Error < StandardError; end

    def initialize(username, password = '')
      @username = username
      @password = password.to_s
      request(:authenticate)
    end

    def add(url, title = '', selection = '')
      response = request(:add, url: url, title: title, selection: selection)
      raise Error, "Instapaper answered #{response.code} for #{url}" unless response.code == '201'

      message = "Success: #{url}"
      message += " Title: #{title}" unless title.nil?
      Automatic::Log.puts(:info, message)
      response
    end

    private

    # TLS with the certificate verified, which is Net::HTTP's own default and
    # is stated here because this plugin used to turn it off.
    def request(method, params = {})
      post = Net::HTTP::Post.new("/api/#{method}")
      post.basic_auth(@username, @password)
      post.set_form_data(params)

      Net::HTTP.start(HOST, 443,
                      use_ssl: true,
                      verify_mode: OpenSSL::SSL::VERIFY_PEER,
                      open_timeout: OPEN_TIMEOUT,
                      read_timeout: READ_TIMEOUT) { |http| http.request(post) }
    end
  end

  class PublishInstapaper
    attr_accessor :instapaper

    def initialize(config, pipeline = [])
      @config     = config || {}
      @pipeline   = pipeline
      @instapaper = Instapaper.new(@config['email'], @config['password'])
    end

    # Adds each item to Instapaper.
    def run
      @pipeline.each do |feeds|
        next if feeds.nil?

        feeds.items.each { |feed| add(feed) }
      end
      @pipeline
    end

    private

    def add(feed)
      Automatic::Log.puts('info', "add: #{feed.link}")
      retries   = 0
      retry_max = @config['retry'].to_i
      begin
        instapaper.add(feed.link, feed.title, feed.description)
      rescue StandardError => e
        retries += 1
        # The message names the item, never the account or the password.
        Automatic::Log.puts('error',
                            "ErrorCount: #{retries}, Fault in publish to instapaper: #{e.message}")
        if retries <= retry_max
          sleep(@config['interval'].to_i)
          retry
        end
      end
      sleep(@config['interval'].to_i)
    end
  end
end
