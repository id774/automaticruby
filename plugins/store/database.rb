# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Database
# Author::    kzgs
#             774 <http://id774.net>
#             soramugi <http://soramugi.net>
# Created::   Feb 27, 2012
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'active_record'

module Automatic::Plugin
  module Database
    def for_each_new_feed
      prepare_database
      existing_records = model_class.all
      @return_feeds = []
      @pipeline.each {|feeds|
        unless feeds.nil?
          new_feeds = []
          feeds.items.each {|feed|
            unless feed.link.nil?
              if unique_keys.length > 1
                detection = existing_records.detect {|b| b.try(unique_keys[0]) == feed.link || b.try(unique_keys[1]) == feed.title }
              else
                detection = existing_records.detect {|b| b.try(unique_keys[0]) == feed.link }
              end
              unless detection
                yield(feed)
                new_feeds << feed
              end
            end
          }
          @return_feeds << Automatic::FeedMaker.create_pipeline(new_feeds) if new_feeds.length > 0
        end
      }
      @return_feeds
    end

    private

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
      Automatic::Log.puts("info", "Using Database: #{db}")
      ActiveRecord::Base.establish_connection(
        :adapter  => "sqlite3",
        :database => db)
      create_table unless model_class.table_exists?
    end
  end
end
