# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Limit
# Description:: Limit the number of items passed by the whole pipeline.
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 24, 2026
# Updated::     Aug 24, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterLimit
    def initialize(config, pipeline = [])
      @config    = config || {}
      @pipeline  = pipeline
      @max_items = validated_max_items
    end

    # Selects items in feed order, item order, up to max_items shared across the
    # whole pipeline rather than reset per feed. A feed that contributed no item
    # is dropped from the output; the walk stops as soon as the limit is met.
    def run
      remaining = @max_items
      returned  = []

      @pipeline.each do |feeds|
        next if feeds.nil?
        break if remaining <= 0

        selected = feeds.items.first(remaining)
        next if selected.empty?

        returned << Automatic::FeedMaker.create_pipeline(selected)
        remaining -= selected.size
      end

      returned
    end

    private

    def validated_max_items
      value = begin
        Integer(@config['max_items'].to_s, 10)
      rescue ArgumentError
        nil
      end

      if value.nil? || value < 1
        raise ArgumentError, 'FilterLimit needs max_items to be a positive integer'
      end

      value
    end
  end
end
