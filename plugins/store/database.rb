# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Database
# Author::    kzgs
#             774 <http://id774.net>
#             soramugi <http://soramugi.net>
# Created::   Feb 27, 2012
# Updated::   Dec 13, 2012
# Copyright:: kzgs Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'active_record'
require 'rss'

module Automatic::Plugin
  module Database
    def for_each_new_feed
      prepare_database
      existing_records = model_class.find(:all)
      @return_feeds = []
      @pipeline.each {|feeds|
        unless feeds.nil?
          new_feeds = []
          feeds.items.each {|feed|
            unless feed.link.nil?
              unless existing_records.detect {|b| b.try(unique_key) == feed.link }
                yield(feed)
                new_feeds << feed
              end
            end
          }
          @return_feeds << create_rss(new_feeds)
        end
      }
      @return_feeds
    end

    private

    def create_rss(feeds)
      RSS::Maker.make("2.0") {|maker|
        xss = maker.xml_stylesheets.new_xml_stylesheet
        xss.href = "http://www.rssboard.org/rss-specification"
        maker.channel.about = "http://feeds.rssboard.org/rssboard"
        maker.channel.title = "Automatic Ruby"
        maker.channel.description = "Automatic Ruby"
        maker.channel.link = "http://www.rssboard.org/rss-specification"
        maker.items.do_sort = true
        unless feeds.nil?
          feeds.each {|feed|
            unless feed.link.nil?
              item             = maker.items.new_item
              item.title       = feed.title
              item.link        = feed.link
              item.date        = Time.now
              item.description = "Automatic::Plugin::Store::Database"
            end
          }
        end
      }
    end

    def create_table
      ActiveRecord::Migration.create_table(model_class.table_name) {|t|
        column_definition.each_pair {|column_name, column_type|
          t.column column_name, column_type
        }
      }
    end

    def db_dir
      dir = (File.expand_path('~/.automatic/db'))
      if File.directory?(dir)
        dir
      else
        File.join(File.dirname(__FILE__), '..', '..', 'db')
      end
    end

    def prepare_database
      db = File.join(db_dir, @config['db'])
      Automatic::Log.puts("info", "Database: #{db}")
      ActiveRecord::Base.establish_connection(
        :adapter  => "sqlite3",
        :database => db)
      create_table unless model_class.table_exists?
    end
  end
end
