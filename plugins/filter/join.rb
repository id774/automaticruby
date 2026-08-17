# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Join
# Description:: Join every item in the pipeline into one item.
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 17, 2026
# Updated::     Aug 17, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# Many items in, one item out. That is the whole of it: no summarizing, no
# fetching, no knowledge of what reads the result. What the joined description
# is for is decided by whatever the Recipe puts next -- an AI filter, a publish
# plugin, or nothing at all.
#
# The whole pipeline becomes one item rather than one item per feed, because
# the point of joining is to have a single text; a Recipe that wants one item
# per feed still has the feeds separate before this plugin runs.

module Automatic::Plugin
  class FilterJoin
    require 'rss'

    # A title an operator has not set. Short and predictable, in the manner of
    # PublishMarkdown's `(untitled)`; a Recipe that publishes this item names
    # it in `title`.
    DEFAULT_TITLE = 'Joined items'.freeze

    # Where one item ends and the next begins, for whatever reads the joined
    # text. Plain lines rather than markup: the descriptions being joined may
    # be HTML or text, and a delimiter that survives both is one that neither
    # can be mistaken for.
    HEADING = 'ARTICLE'.freeze

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Returns one feed holding one item, or an empty pipeline when there was
    # nothing to join. An item saying nothing is worse than no item: the
    # plugins after this one would publish it.
    def run
      items = collect
      if items.empty?
        Automatic::Log.puts('warn', 'FilterJoin: no items to join')
        return []
      end

      Automatic::Log.puts('info', "FilterJoin: joining #{items.size} items into one")
      [feed(title, description(items))]
    end

    private

    def collect
      @pipeline.each_with_object([]) { |feeds, items|
        next if feeds.nil?

        items.concat(feeds.items)
      }
    end

    def title
      given = @config['title'].to_s
      given.empty? ? DEFAULT_TITLE : given
    end

    def description(items)
      items.each_with_index.map { |item, index| section(index + 1, item) }.join("\n\n")
    end

    def section(number, item)
      ["#{HEADING} #{number}",
       "Title: #{value(item, :title)}",
       "URL: #{value(item, :link)}",
       '',
       value(item, :description)].join("\n")
    end

    # A field an item does not carry is empty rather than absent, so that every
    # section has the same shape whatever the feed it came from left out.
    def value(item, name)
      return '' unless item.respond_to?(name)

      item.public_send(name).to_s.strip
    end

    # Built here rather than through FeedMaker.create_pipeline, which drops an
    # item whose link is nil -- and this item's link is nil deliberately. It is
    # several articles at once, so there is no page it points at, and putting
    # the first article's URL there would name a source for text that is not
    # only from it.
    def feed(item_title, item_description)
      RSS::Maker.make('2.0') { |maker|
        maker.channel.title = 'Automatic Ruby'
        maker.channel.description = 'Automatic::Plugin::FilterJoin'
        maker.channel.link = 'https://github.com/id774/automaticruby'
        item = maker.items.new_item
        item.title = item_title
        item.description = item_description
        item.date = Time.now
      }
    end
  end
end
