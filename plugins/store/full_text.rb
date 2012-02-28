#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::FullText
# Author::    774 <http://id774.net>
# Created::   Feb 26, 2012
# Updated::   Feb 28, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.
require 'plugins/store/store_database'

module Automatic::Plugin
  class Blog < ActiveRecord::Base
  end

  class StoreFullText
    include Automatic::Plugin::StoreDatabase
    
    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def column_definition
      return {
        :title => :string,
        :link => :string,
        :description => :string,
        :content => :string,
        :created_at => :string,
      }
    end

    def unique_key
      return :link
    end

    def model_class
      return Automatic::Plugin::Blog
    end

    def run
      return for_each_new_feed { |feed|
        begin
          Blog.create(
            :title => feed.title,
            :link => feed.link,
            :description => feed.description,
            :content => feed.content_encoded,
            :created_at => Time.now.strftime("%Y/%m/%d %X"))
        rescue
          Automatic::Log.puts("warn", "Skip feed due to fault in save.")
        end
      }
    end
  end
end
