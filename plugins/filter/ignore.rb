# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Ignore
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 22, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterIgnore
    FIELDS = %i[title link description].freeze

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Drops items containing any listed keyword. Matching is a substring test,
    # so an empty keyword drops everything.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        kept = feeds.nil? ? [] : feeds.items.reject { |item| exclude?(item) }
        returned << Automatic::FeedMaker.create_pipeline(kept) unless kept.empty?
      end
    end

    private

    def exclude?(item)
      FIELDS.any? do |field|
        Array(@config[field.to_s]).any? do |keyword|
          excluded?(item.send(field), keyword.to_s.chomp, field)
        end
      end
    end

    # An item whose field is missing is kept, with a warning.
    def excluded?(value, keyword, field)
      unless value.respond_to?(:include?)
        Automatic::Log.puts('warn', "Invalid feed detected in ignore process with #{value}")
        return false
      end

      return false unless value.include?(keyword)

      Automatic::Log.puts('info', "Excluded by #{field}: #{value}")
      true
    end
  end
end
