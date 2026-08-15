# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Accept
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun  4, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterAccept
    FIELDS = %i[title link description].freeze

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # The complement of FilterIgnore: keeps only the items that match. Matching
    # is a substring test, so an empty keyword matches everything.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        kept = feeds.nil? ? [] : feeds.items.select { |item| contain?(item) }
        returned << Automatic::FeedMaker.create_pipeline(kept) unless kept.empty?
      end
    end

    private

    def contain?(item)
      FIELDS.any? do |field|
        Array(@config[field.to_s]).any? do |keyword|
          matched?(item, field, keyword.to_s.chomp)
        end
      end
    end

    # An item whose field is missing is not matched, and says so. The earlier
    # version called #include? on it and ended the run with a NoMethodError,
    # which is not what the complementary filter does with the same item.
    def matched?(item, field, keyword)
      value = item.send(field)
      unless value.respond_to?(:include?)
        Automatic::Log.puts('warn', "Invalid feed detected in accept process with #{field}")
        return false
      end

      return false unless value.include?(keyword)

      Automatic::Log.puts('info', "Contain by #{field}: #{item.link}")
      true
    end
  end
end
