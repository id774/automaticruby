#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Dump
# Author::    774 <http://id774.net>
# Created::   Jun 13, 2012
# Updated::   Jun 13, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishDump
    require 'pp'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @pipeline.each { |contents|
        pp contents
      }
      @pipeline
    end
  end
end
