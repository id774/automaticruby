#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Permalink
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Feb 22, 2012
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

require_relative 'database'

module Automatic::Plugin
  class Permalink < ActiveRecord::Base
  end

  class StorePermalink
    include Automatic::Plugin::Database

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def column_definition
      {
        :url => :string,
        :created_at => :string
      }
    end

    def unique_keys
      [:url]
    end

    def model_class
      Automatic::Plugin::Permalink
    end

    def run
      for_each_new_feed {|feed|
        unless feed.link.nil?
          Permalink.create(
            :url => feed.link,
            :created_at => Time.now.strftime("%Y/%m/%d %X"))
          Automatic::Log.puts("info", "Saving Permalink: #{feed.link}")
        end
      }
    end
  end
end
