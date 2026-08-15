# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Notify::Ikachan
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar  7, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# Description:: Posts each item to an IRC channel through an ikachan
#               HTTP-to-IRC gateway, which the operator runs themselves.

require 'net/http'
require 'uri'

module Automatic::Plugin
  class Ikachan
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30

    attr_accessor :params

    def initialize
      @params = { 'url' => '', 'port' => '', 'channels' => [], 'command' => '' }
    end

    def post(link, title = '')
      message = build_message(link, title)
      uri     = endpoint

      start(uri) do |http|
        channels.each do |channel|
          # Join first, in case the gateway is not in the channel.
          http.request(form('/join', channel: channel))
          response = http.request(form(uri.path, channel: channel, message: message))
          log(response, message)
        end
      end
    end

    private

    # A gateway reached over https is spoken to over https. The earlier
    # version built a plain connection whatever the URL said.
    def start(uri, &block)
      proxy = Net::HTTP.Proxy(ENV.fetch('PROXY', nil), 8080)
      proxy.start(uri.host, uri.port,
                  use_ssl: uri.scheme == 'https',
                  open_timeout: OPEN_TIMEOUT,
                  read_timeout: READ_TIMEOUT, &block)
    end

    # Form-encoded by Net::HTTP rather than interpolated into the body, so
    # that a title carrying an ampersand or a space reaches the channel as it
    # was written instead of splitting the request.
    def form(path, params)
      request = Net::HTTP::Post.new(path)
      request.set_form_data(params)
      request
    end

    def channels
      value = @params['channels']
      value.is_a?(Array) ? value : value.to_s.split(',')
    end

    def endpoint
      URI.parse("#{@params['url']}:#{@params['port']}/#{@params['command']}")
    end

    def log(response, message)
      if response.code == '200'
        Automatic::Log.puts(:info, "Success: #{message}")
      else
        Automatic::Log.puts(:error, "#{response.code} Error: #{message}")
      end
    end

    def build_message(link, title)
      message = ''
      message += "#{title} - " unless title.nil? || title.to_s.empty?
      message + link.to_s
    end
  end

  class NotifyIkachan
    attr_accessor :ikachan

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline

      @ikachan = Ikachan.new
      @ikachan.params = {
        'url'      => @config['url'],
        'port'     => @config['port'] || '4979',
        'channels' => channels,
        'command'  => @config['command'] || 'notice'
      }
    end

    # Returns the pipeline unchanged: a Notify plugin sends a notification and
    # nothing else.
    def run
      @pipeline.each do |feeds|
        next if feeds.nil?

        feeds.items.each do |feed|
          Automatic::Log.puts('info', "Ikachan: [#{feed.link}] sending to #{channels.join(',')}...")
          ikachan.post(feed.link, feed.title)
          sleep(@config['interval'].to_i)
        end
      end
      @pipeline
    end

    private

    # Comma separated, with a leading '#' added where it is absent.
    def channels
      @config['channels'].to_s.split(',').map { |name| name.start_with?('#') ? name : "##{name}" }
    end
  end
end
