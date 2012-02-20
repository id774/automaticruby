#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "feed_parser"
require "hb"
require 'active_record'

class Bookmark < ActiveRecord::Base
end

class AutoBookmark
  attr_accessor :hb

  def initialize
    user = []
    IO.foreach(File.join(File.dirname(__FILE__), '..', 'config', 'user.txt')) {|u|
      user << u
    }

    @hb = HatenaBookmark.new
    @hb.user = {
      "hatena_id" => user[0].chomp,
      "password"  => user[1].chomp
    }

    @feeds = []
    IO.foreach(File.join(File.dirname(__FILE__), '..', 'config', 'feeds.txt')) {|feed|
      @feeds << feed
    }
  end

  def create_db
    ActiveRecord::Migration.create_table :bookmarks do |t|
      t.column :url, :string
      t.column :created_at, :string
    end
  end

  def bookmark
    ActiveRecord::Base.establish_connection(
      :adapter  => "sqlite3",
      :database => (File.join(File.dirname(__FILE__), '..', 'db', 'bookmark.db'))
    )

    create_db unless Bookmark.table_exists?()

    bookmark = Bookmark.find(:all)
    @feeds.each {|feed|
      begin
        t = Time.now.strftime("%Y/%m/%d %X")
        puts "#{t} [info] Parsing: #{feed}"
        links = FeedParser.get_rss(feed)
        links.each {|link|
          unless bookmark.detect {|b|b.url == link}
            t = Time.now.strftime("%Y/%m/%d %X")
            print "#{t} [info] Bookmarking: #{link}\n"
            new_bookmark = Bookmark.new(:url => link, :created_at => t)
            new_bookmark.save
            hb.post(link, nil)
            sleep 5
          end
        }
      rescue
        t = Time.now.strftime("%Y/%m/%d %X")
        puts "#{t} [error] Fault in parsing: #{feed}"
      end
    }
  end
end
