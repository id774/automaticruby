# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Pocket
# Author: soramugi (More info: http://soramugi.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   May 15, 2013
# Updated::   Jan 15, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.

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
            retry_max = @config['retry'].to_i || 0
            begin
              @client.add(:url => feed.link)
              Automatic::Log.puts("info", "add: #{feed.link}")
            rescue
              retries += 1
              Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in publish to pocket.")
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
