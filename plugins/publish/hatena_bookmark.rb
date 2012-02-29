#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::HatenaBookmark
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Mar  1, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishHatenaBookmark
    require 'hatenabm'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline

      @hb = HatenaBM.new(
        :user => @config['username'],
        :pass => @config['password']
      )
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            Automatic::Log.puts("info", "Bookmarking: #{feed.link}")
            @hb.post(:link => feed.link)
            sleep @config['interval'].to_i
          }
        end
      }
      @pipeline
    end
  end
end
