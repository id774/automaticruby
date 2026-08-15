# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Store::Database
# Author:       kzgs
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 27, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# The SQLite storage the store plugins share. ActiveRecord and sqlite3 are the
# store plugins' own dependencies, not the framework's: a Recipe that stores
# nothing runs without them. See doc/POLICY.md section 9.1.

Automatic.require_optional('active_record',
                           gem_name: 'activerecord',
                           needed_by: 'the store plugins StorePermalink and StoreFullText')
Automatic.require_optional('sqlite3',
                           needed_by: 'the store plugins StorePermalink and StoreFullText')

module Automatic::Plugin
  module Database
    # Yields each item that is not already in the table, and returns a pipeline
    # of those items. An item with no link is neither stored nor passed on.
    def for_each_new_feed
      prepare_database

      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil?

        new_feeds = feeds.items.reject { |feed| feed.link.nil? || stored?(feed) }
        new_feeds.each { |feed| yield(feed) }
        returned << Automatic::FeedMaker.create_pipeline(new_feeds) unless new_feeds.empty?
      end
    end

    private

    # Asked of the database rather than of every row loaded into memory, which
    # is what this did before: a store whose database has grown to a year of
    # links reads one index entry per item now instead of the whole table per
    # run.
    def stored?(feed)
      scope = model_class.where(unique_keys[0] => feed.link)
      scope = scope.or(model_class.where(unique_keys[1] => feed.title)) if unique_keys.length > 1
      scope.exists?
    end

    def create_table
      ActiveRecord::Base.connection.create_table(model_class.table_name) do |table|
        column_definition.each_pair do |name, type|
          table.column name, type
        end
      end
    end

    def db_dir
      dir = File.expand_path('~/.automatic/db')
      return dir if File.directory?(dir)

      File.expand_path('../../db', __dir__)
    end

    def prepare_database
      db = File.join(db_dir, @config['db'].to_s)
      Automatic::Log.puts('info', "Using Database: #{db}")
      ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: db)
      create_table unless ActiveRecord::Base.connection.table_exists?(model_class.table_name)
    end
  end
end
