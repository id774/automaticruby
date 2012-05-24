# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Database
# Author::    kzgs
# Created::   Feb 27, 2012
# Updated::   May 24, 2012
# Copyright:: kzgs Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'active_record'

module Automatic::Plugin
  module StoreDatabase
    def for_each_new_link
      prepare_database
      existing_records = model_class.find(:all)
      return_feeds = []
      @pipeline.each { |link|
        unless link.nil?
          new_link = false
          unless existing_records.detect { |b| b.try(unique_key) == link }
            yield(link)
            new_link = true
          end
          return_feeds << link if new_link
        end
      }
      return_feeds
    end

    def for_each_new_feed
      prepare_database
      existing_records = model_class.find(:all)
      return_feeds = []
      @pipeline.each { |feeds|
        unless feeds.nil?
          new_feed = false
          feeds.items.each { |feed|
            unless existing_records.detect { |b| b.try(unique_key) == feed.link }
              yield(feed)
              new_feed = true
            end
          }
          return_feeds << feeds if new_feed
        end
      }
      return_feeds
    end

    private

    def create_table
      ActiveRecord::Migration.create_table(model_class.table_name) { |t|
        column_definition.each_pair { |column_name, column_type|
          t.column column_name, column_type
        }
      }
    end

    def db_dir
      return File.join(File.dirname(__FILE__), '..', '..', 'db')
    end

    def prepare_database
      ActiveRecord::Base.establish_connection(
        :adapter  => "sqlite3",
        :database => File.join(db_dir, @config['db']))
      create_table unless model_class.table_exists?
    end
  end
end
