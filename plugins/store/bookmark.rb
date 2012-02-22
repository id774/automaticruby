#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Bookmark
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 22, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'active_record'

class Bookmark < ActiveRecord::Base
end

class StoreBookmark
  attr_accessor :hb

  def initialize(config, pipeline=[])
    @config = config
    @pipeline = pipeline
  end

  def create_table
    ActiveRecord::Migration.create_table :bookmarks do |t|
      t.column :url, :string
      t.column :created_at, :string
    end
  end

  def run
    ActiveRecord::Base.establish_connection(
      :adapter  => "sqlite3",
      :database => (File.join(File.dirname(__FILE__),
                    '..', '..', 'db', @config['db']))
    )
    create_table unless Bookmark.table_exists?()

    bookmarks = Bookmark.find(:all)
    return_feeds = []
    @pipeline.each {|feeds|
      unless feeds.nil?
        feeds.items.each {|feed|
          unless bookmarks.detect {|b|b.url == feed.link}
            new_bookmark = Bookmark.new(:url => feed.link,
              :created_at => Time.now.strftime("%Y/%m/%d %X"))
            new_bookmark.save
            return_feeds << feeds
          end
        }
      end
    }
    return_feeds
  end
end
