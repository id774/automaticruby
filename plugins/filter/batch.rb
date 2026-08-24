# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Batch
# Description:: Group the whole pipeline into fixed-size item batches.
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 24, 2026
# Updated::     Aug 24, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterBatch
    require 'rss'

    # Where one source item ends and the next begins inside a batch's
    # description, in the manner of FilterJoin's own delimiter -- but built
    # independently, since a batch item is not a joined item.
    HEADING = 'ARTICLE'.freeze

    def initialize(config, pipeline = [])
      @config      = config || {}
      @pipeline    = pipeline
      @batch_items = validated_batch_items
    end

    # Collects the whole pipeline into one Array, discarding feed boundaries,
    # and slices it into fixed-size batches. Each batch becomes one item in one
    # output feed.
    def run
      items = collect
      return [] if items.empty?

      feed(items.each_slice(@batch_items).to_a)
    end

    private

    def validated_batch_items
      value = begin
        Integer(@config['batch_items'].to_s, 10)
      rescue ArgumentError
        nil
      end

      if value.nil? || value < 1
        raise ArgumentError, 'FilterBatch needs batch_items to be a positive integer'
      end

      value
    end

    def collect
      @pipeline.each_with_object([]) do |feeds, items|
        next if feeds.nil?

        items.concat(feeds.items)
      end
    end

    def feed(batches)
      [RSS::Maker.make('2.0') { |maker|
        maker.channel.title = 'Automatic Ruby'
        maker.channel.description = 'Automatic::Plugin::FilterBatch'
        maker.channel.link = 'https://github.com/id774/automaticruby'
        maker.items.do_sort = false

        batches.each_with_index do |batch, index|
          item = maker.items.new_item
          item.title = "Batch #{index + 1}"
          item.description = description(batch)
          item.date = Time.now
        end
      }]
    end

    def description(batch)
      batch.each_with_index.map { |item, index| section(index + 1, item) }.join("\n\n")
    end

    def section(number, item)
      ["#{HEADING} #{number}",
       "Title: #{value(item, :title)}",
       "URL: #{value(item, :link)}",
       '',
       value(item, :description)].join("\n")
    end

    # A field an item does not carry is empty rather than absent, so that every
    # ARTICLE has the same shape whatever the feed it came from left out.
    def value(item, name)
      return '' unless item.respond_to?(name)

      item.public_send(name).to_s.strip
    end
  end
end
