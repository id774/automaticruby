#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'active_record'

class Bookmark < ActiveRecord::Base
end

class PublishHatenaBookmark
  attr_accessor :hb

  def initialize(config, pipeline=[])
    @config = config
    @pipeline = pipeline

    @hb = HatenaBookmark.new
    @hb.user = {
      "hatena_id" => @config['username'],
      "password"  => @config['password']
    }
  end

  def create_db
    ActiveRecord::Migration.create_table :bookmarks do |t|
      t.column :url, :string
      t.column :created_at, :string
    end
  end

  def filtering_url(link)
    detection = false
    @config['exclude'].each {|e|
      detection = true if link.include?(e.chomp)
    }
    if detection
      Log.puts("info", "Excluded: #{link}")
    end
    return detection
  end

  def bookmark
    ActiveRecord::Base.establish_connection(
      :adapter  => "sqlite3",
      :database => (File.join(File.dirname(__FILE__),
                    '..', '..', 'db', @config['db']))
    )

    create_db unless Bookmark.table_exists?()

    bookmarks = Bookmark.find(:all)
    @pipeline.each {|links|
      links.each {|link|
        unless filtering_url(link)
          unless bookmarks.detect {|b|b.url == link}
            Log.puts("info", "Bookmarking: #{link}")
            new_bookmark = Bookmark.new(:url => link,
              :created_at => Time.now.strftime("%Y/%m/%d %X"))
            new_bookmark.save
            hb.post(link, nil)
            sleep 5
          end
        end
      }
    }
  end

  def run
    bookmark
  end
end
