# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Store::FullText
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 26, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require_relative 'database'

module Automatic::Plugin
  class Blog < ActiveRecord::Base
  end

  class StoreFullText
    include Automatic::Plugin::Database

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    def column_definition
      {
        title: :string,
        link: :string,
        description: :string,
        content: :string,
        created_at: :string
      }
    end

    # Link or title, so that a republished article with a new URL is not
    # stored twice.
    def unique_keys
      %i[link title]
    end

    def model_class
      Automatic::Plugin::Blog
    end

    # Records title, link, description and content_encoded, and passes on only
    # what is new.
    def run
      for_each_new_feed do |feed|
        Automatic::Log.puts('info', "Saving FullText: #{feed.link}")
        begin
          Blog.create(
            title: feed.title,
            link: feed.link,
            description: feed.description,
            content: feed.content_encoded,
            created_at: Time.now.strftime('%Y/%m/%d %X')
          )
        rescue StandardError => e
          Automatic::Log.puts('warn', "Skip feed due to fault in save: #{e.message}")
        end
      end
    end
  end
end
