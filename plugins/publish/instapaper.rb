# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Instapaper
# Author::    soramugi <http://soramugi.net>
#             774 <http://id774.net>
# Created::   Feb  9, 2013
# Updated::   Mar 23, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
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
        raise
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
            retries = 0
            begin
              instapaper.add(feed.link, feed.title, feed.description)
            rescue
              retries += 1
              Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in publish to instapaper.")
              sleep @config['interval'].to_i unless @config['interval'].nil?
              retry if retries <= @config['retry'].to_i unless @config['retry'].nil?
            end
            sleep @config['interval'].to_i unless @config['interval'].nil?
          }
        end
      }
      @pipeline
    end
  end
end
