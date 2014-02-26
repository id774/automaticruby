# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Hipchat
# Author::    Kohei Hasegawa <http://github.com/banyan>
# Created::   Jun  6, 2013
# Updated::   Jan 15, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
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
            retry_max = @config['retry'].to_i || 0
            begin
              @client.send(@config['username'], feed.description, @options)
              Automatic::Log.puts("info", "Hipchat post: #{feed.description.gsub(/[\r\n]/,'')[0..50]}...") rescue nil
            rescue => e
              retries += 1
              Automatic::Log.puts("error", "ErrorCount: #{retries}, #{e.message}")
              sleep ||= @config['interval'].to_i
              retry if retries <= retry_max
            end
            sleep ||= @config['interval'].to_i
          }
        end
      }
      @pipeline
    end
  end
end
