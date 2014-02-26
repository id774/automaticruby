#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Permalink
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Sep 18, 2012
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'plugins/store/database'

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

    def unique_key
      :url
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
