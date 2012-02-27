#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Bookmark
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 22, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.
require 'plugins/store/store_database'

module Automatic::Plugin  
  class Bookmark < ActiveRecord::Base
  end

  class StoreBookmark
    include Automatic::Plugin::StoreDatabase

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def column_definition
      return {
        :url => :string,
        :created_at => :string
      } 
    end
    
    def unique_key
      return :url
    end

    def model_class
      return Automatic::Plugin::Bookmark
    end
    
    def run
      return for_each_new_feed { |feed|
        Bookmark.create(
          :url => feed.link,
          :created_at => Time.now.strftime("%Y/%m/%d %X"))
      }
    end
  end
end
