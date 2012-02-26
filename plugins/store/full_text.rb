#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::FullText
# Author::    774 <http://id774.net>
# Created::   Feb 26, 2012
# Updated::   Feb 26, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.
require 'active_record'

module Automatic::Plugin
  class Blog < ActiveRecord::Base
  end

  class StoreFullText
    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def create_table
      ActiveRecord::Migration.create_table :blogs do |t|
        t.column :title, :string
        t.column :link, :string
        t.column :description, :string
        t.column :content, :string
        t.column :created_at, :string
      end
    end

    def run
      ActiveRecord::Base.establish_connection(
        :adapter  => "sqlite3",
        :database => (File.join(File.dirname(__FILE__),
          '..', '..', 'db', @config['db'])))
      create_table unless Blog.table_exists?()
      blogs = Blog.find(:all)
      return_feeds = []
      @pipeline.each {|feeds|
        unless feeds.nil?
          new_feed = false
          feeds.items.each {|feed|
            unless blogs.detect {|b|b.link == feed.link}
              new_blog = Blog.new(
                :title => feed.title,
                :link => feed.link,
                :description => feed.description,
                :content => feed.content_encoded,
                :created_at => Time.now.strftime("%Y/%m/%d %X"))
              new_blog.save
              new_feed = true
            end
          }
          return_feeds << feeds if new_feed
        end
      }
      return_feeds
    end
  end
end
