# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Pocket
# Author::    soramugi <http://soramugi.net>
# Created::   May 15, 2013
# Updated::   May 15, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishPocket
    require 'pocket'

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
      Pocket.configure do |c|
        c.consumer_key = @config['consumer_key']
        c.access_token = @config['access_token']
      end
      @client = Pocket.client
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            retries = 0
            begin
              @client.add(:url => feed.link)
              Automatic::Log.puts("info", "add: #{feed.link}")
            rescue
              retries += 1
              Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in publish to pocket.")
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
