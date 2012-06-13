#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::ImageLink
# Author::    774 <http://id774.net>
# Created::   May 24, 2012
# Updated::   Jun 13, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterImageLink
    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_html = []
      @pipeline.each {|html|
        unless html.nil?
          html.scan(/(.*?\.jp.*g$)/i) { |matched|
            @return_html << matched.join(" ")
          }
          html.scan(/(.*?\.png$)/i) { |matched|
            @return_html << matched.join(" ")
          }
          html.scan(/(.*?\.gif$)/i) { |matched|
            @return_html << matched.join(" ")
          }
          html.scan(/(.*?\.tiff$)/i) { |matched|
            @return_html << matched.join(" ")
          }
        end
      }
      @return_html
    end
  end
end
