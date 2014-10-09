# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::FullText
# Author::    774 <http://id774.net>
# Created::   Feb 26, 2012
# Updated::   Jun 14, 2012
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'plugins/store/database'

module Automatic::Plugin
  class Blog < ActiveRecord::Base
  end

  class StoreFullText
    include Automatic::Plugin::Database

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def column_definition
      {
        :title => :string,
        :link => :string,
        :description => :string,
        :content => :string,
        :created_at => :string,
      }
    end

    def unique_keys
      [:link, :title]
    end

    def model_class
      Automatic::Plugin::Blog
    end

    def run
      for_each_new_feed {|feed|
        Automatic::Log.puts("info", "Saving FullText: #{feed.link}")
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
