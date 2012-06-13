# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::URI
# Author::    774 <http://id774.net>
# Created::   May 24, 2012
# Updated::   Jun 13, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionURI
    require 'open-uri'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @config['urls'].each {|url|
        begin
          Automatic::Log.puts("info", "Parsing: #{url}")
          doc = open(url).read
          @pipeline << doc
        rescue
          Automatic::Log.puts("error", "Fault in parsing: #{url}")
        end
      }
      return @pipeline
    end
  end
end
