#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'active_record'

class Bookmark < ActiveRecord::Base
end

class AutoBookmark
  attr_accessor :hb

  def initialize(config)
    @config = config
    @hb = HatenaBookmark.new
    @hb.user = {
      "hatena_id" => @config['plugins']['config']['username'],
      "password"  => @config['plugins']['config']['passowrd']
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
    @config['plugins']['config']['exclude'].each {|e|
      detection = true if link.include?(e.chomp)
    }
    if detection
      t = Time.now.strftime("%Y/%m/%d %X")
      puts "#{t} [info] Excluded: #{link}"
    end
    return detection
  end

  def bookmark
    ActiveRecord::Base.establish_connection(
      :adapter  => "sqlite3",
      :database => (File.join(File.dirname(__FILE__), '..', 'db', 'bookmark.db'))
    )

    create_db unless Bookmark.table_exists?()

    bookmarks = Bookmark.find(:all)
    @config['plugins']['config']['feeds'].each {|feed|
      begin
        t = Time.now.strftime("%Y/%m/%d %X")
        puts "#{t} [info] Parsing: #{feed}"
        links = FeedParser.get_rss(feed)
        links.each {|link|
          unless filtering_url(link)
            unless bookmarks.detect {|b|b.url == link}
              t = Time.now.strftime("%Y/%m/%d %X")
              print "#{t} [info] Bookmarking: #{link}\n"
              new_bookmark = Bookmark.new(:url => link, :created_at => t)
              new_bookmark.save
              hb.post(link, nil)
              sleep 5
            end
          end
        }
      rescue
        t = Time.now.strftime("%Y/%m/%d %X")
        puts "#{t} [error] Fault in parsing: #{feed}"
      end
    }
  end

  def run
    bookmark
  end
end
