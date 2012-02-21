#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

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

  def save
    ActiveRecord::Base.establish_connection(
      :adapter  => "sqlite3",
      :database => (File.join(File.dirname(__FILE__),
                    '..', '..', 'db', @config['db']))
    )
    create_table unless Bookmark.table_exists?()

    bookmarks = Bookmark.find(:all)
    targets = []
    @pipeline.each {|links|
      target = []
      links.each {|link|
        unless bookmarks.detect {|b|b.url == link}
          new_bookmark = Bookmark.new(:url => link,
            :created_at => Time.now.strftime("%Y/%m/%d %X"))
          new_bookmark.save
          target << link
        end
      }
      targets << target
    }
    targets
  end

  def run
    save
  end
end
