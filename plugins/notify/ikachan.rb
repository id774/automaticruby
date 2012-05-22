#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'active_support/core_ext'

module Automatic::Plugin
  class Ikachan
    require 'rubygems'
    require 'time'
    require 'net/http'
    require 'uri'

    attr_accessor :params

    def initialize
      @params = {
        "url"      => "",
        "port"     => "",
        "channels" => [],
        "command"  => "",
      }
    end

    def endpoint_url
      "#{@params['url']}:#{@params['port']}/#{@params['command']}"
    end

    def post(link, title = "")
      message     = build_message(link, title)
      uri         = URI.parse(endpoint_url)
      proxy_class = Net::HTTP::Proxy(ENV["PROXY"], 8080)
      http        = proxy_class.new(uri.host, uri.port)
      http.start do |http|
        @params['channels'].split(",").each do|channel|
          # send join command to make sure when if ikachan is not in the channel
          http.post("/join", "channel=#{channel}")
          res = http.post(uri.path, %Q(channel=#{channel}&message=#{message}))
          if res.code == "200"
            Automatic::Log.puts(:info, "Success: #{message}")
          else
            Automatic::Log.puts(:error, "#{res.code} Error: #{message}")
          end
        end
      end
    end

    private

    def build_message(link, title)
      message = ""
      message += "#{title.to_s} - " unless title.blank?
      message += link.to_s
      message
    end
  end

  class NotifyIkachan
    attr_accessor :ikachan

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline

      @ikachan = Ikachan.new
      @ikachan.params = {
        "url"      => @config['url'],
        "port"     => @config['port'] || "4979",
        "channels" => @config['channels'].split(',').map{ |v| v.match(/^#/) ? v : "#" + v }, # Prifixing '#'
        "command"  => @config['command'] || "notice",
      }
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            Automatic::Log.puts("info", %Q(Ikachan: [#{feed.link}] sending with params #{ikachan.params.to_s}...))
            ikachan.post(feed.link, feed.title)
            sleep @config['interval'].to_i
          }
        end
      }
      @pipeline
    end
  end
end
