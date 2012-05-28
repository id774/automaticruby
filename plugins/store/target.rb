#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Target
# Author::    774 <http://id774.net>
# Created::   May 24, 2012
# Updated::   May 28, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class StoreTarget
    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def wget(url)
      filename = url.split(/\//).last
      open(url) { |source|
        open(File.join(@config['path'], filename), "w+b") { |o|
          o.print source.read
        }
      }
    end

    def run
      @pipeline.each {|html|
        begin
          unless html.nil?
            Automatic::Log.puts("info", "Get: #{html}")
            wget(html)
          end
        rescue
          Automatic::Log.puts("error", "Error found during file download.")
        end
        sleep @config['interval'].to_i
      }
      @pipeline
    end
  end
end
