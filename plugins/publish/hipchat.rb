# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Hipchat
# Author::    Kohei Hasegawa <http://github.com/banyan>
# Created::   Jun 6, 2013
# Updated::   Jun 6, 2013
# Copyright:: Kohei Hasegawa Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  require 'hipchat'

  class PublishHipchat
    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
      @options = {
        'color'  => 'yellow',
        'notify' => false
      }
      @options.merge!(@config.select { |k, v| @options.include?(k) })
      @client = HipChat::Client.new(@config['api_token'])[@config['room_id']]
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            retries = 0
            begin
              @client.send(@config['username'], feed.description, @options)
              Automatic::Log.puts("info", "post: #{feed.description.gsub(/[\r\n]/,'')[0..50]}...") rescue nil
            rescue => e
              retries += 1
              Automatic::Log.puts("error", "ErrorCount: #{retries}, #{e.message}")
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
