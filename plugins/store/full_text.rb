# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Store::FullText
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 26, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require_relative 'database'

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
