# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Instapaper
# Author::    soramugi <http://soramugi.net>
# Created::   Feb 9, 2013
# Updated::   Feb 9, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class Instapaper
    # @see http://www.instapaper.com/api/simple
    require "net/http"
    require "openssl"

    def initialize(username, password = '')
      @username = username
      @password = password
      request(:authenticate)
    end

    def add(url, title = '', selection = '')
      params = {
        :url       => url,
        :title     => title,
        :selection => selection
      }
      res = request(:add, params)
      if res.code == "201" then
        message = "Success: #{url}"
        message += " Title: #{title}" unless title.nil?
        Automatic::Log.puts(:info, message)
      else
        Automatic::Log.puts(:error, "#{res.code} Error: #{url}")
      end
    end

    private

    def request(method, params = {})
      request          = Net::HTTP::Post.new('/api/' + method.to_s)
      request.basic_auth(@username, @password)
      request.set_form_data(params)
      http             = Net::HTTP.new('www.instapaper.com', 443)
      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.start { http.request(request) }
    end
  end

  class PublishInstapaper

    attr_accessor :instapaper

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline

      @instapaper = Instapaper.new(
        @config['email'],
        @config['password']
      )
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            Automatic::Log.puts("info", "add: #{feed.link}")
            instapaper.add(feed.link, feed.title, feed.description)
            sleep @config['interval'].to_i unless @config['interval'].nil?
          }
        end
      }
      @pipeline
    end
  end
end
