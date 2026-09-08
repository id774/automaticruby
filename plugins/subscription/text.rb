# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::Text
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     May  6, 2013
# Updated::     Sep  8, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class SubscriptionText
    # Columns of a TSV row, in order. A row with fewer columns leaves the rest
    # unset, which is what makes a one-column file of titles a valid input.
    COLUMNS = %w[title url description author comments].freeze

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Reaches no network, which is what makes this the plugin to test a
    # Recipe's later half with. Any combination of the four keys may be given.
    def run
      items = titles + urls + feeds + files
      @pipeline << Automatic::FeedMaker.create_pipeline(items) unless items.empty?
      @pipeline
    end

    private

    def titles
      Array(@config['titles']).map { |title| Automatic::FeedMaker.generate_feed('title' => title) }
    end

    def urls
      Array(@config['urls']).map { |url| Automatic::FeedMaker.generate_feed('url' => url) }
    end

    def feeds
      Array(@config['feeds']).map { |feed| Automatic::FeedMaker.generate_feed(feed) }
    end

    # Tab separated, read as UTF-8, and `~` expanded. Empty columns stay in
    # position and an all-empty row produces no item.
    def files
      Array(@config['files']).flat_map do |path|
        File.foreach(File.expand_path(path), encoding: 'UTF-8').filter_map do |line|
          fields = tsv_fields(line)
          Automatic::FeedMaker.generate_feed(fields) unless fields.nil?
        end
      end
    end

    def tsv_fields(line)
      values = line.chomp.split("\t", -1).first(COLUMNS.length)
      fields = COLUMNS.zip(values).to_h
      fields.delete_if { |_field, value| value.nil? || value.empty? }
      fields unless fields.empty?
    end
  end
end
