#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Link
# Author::    774 <http://id774.net>
# Created::   May 24, 2012
# Updated::   May 28, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterLink
    require 'nokogiri'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_html = []
      @pipeline.each {|html|
        img_url = ""
        unless html.nil?
          doc = Nokogiri::HTML(html)
          (doc/:a).each {|link|
            @return_html << link[:href]
          }
        end
      }
      @return_html
    end
  end
end
