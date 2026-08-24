# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Present
# Description:: Keep items whose configured fields are all present.
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 24, 2026
# Updated::     Aug 24, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterPresent
    # The item fields presence may be checked over. `date` is not one, being
    # absent from a plain summary as often as not, and `enclosure` is not
    # either, being a structure rather than a value.
    FIELDS = %w[title link description author comments source content_encoded].freeze

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @fields   = validated_fields
    end

    # Keeps only the items where every configured field is present. A feed
    # that kept nothing is dropped from the output rather than passed on empty.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil?

        survivors = feeds.items.select { |item| present?(item) }
        returned << Automatic::FeedMaker.create_pipeline(survivors) unless survivors.empty?
      end
    end

    private

    def validated_fields
      given = @config['fields']
      raise ArgumentError, 'FilterPresent takes fields as a list' unless given.is_a?(Array)

      names = given.map(&:to_s)
      raise ArgumentError, 'FilterPresent needs a non-empty fields list' if names.empty?

      unknown = names - FIELDS
      unless unknown.empty?
        raise ArgumentError,
              "FilterPresent cannot inspect #{unknown.join(', ')}; " \
              "the fields are #{FIELDS.join(', ')}"
      end

      duplicated = names.tally.select { |_name, count| count > 1 }.keys
      raise ArgumentError, "FilterPresent was given #{duplicated.join(', ')} twice" unless duplicated.empty?

      names
    end

    def present?(item)
      @fields.all? { |field| field_present?(item, field) }
    end

    # A field an item does not carry, or whose value is nil, is absent. A
    # field whose value answers #content -- a parsed source or enclosure -- is
    # judged on that content rather than on the element itself.
    def field_present?(item, field)
      return false unless item.respond_to?(field)

      value = item.public_send(field)
      return false if value.nil?

      value = value.content if value.respond_to?(:content)
      !value.to_s.strip.empty?
    end
  end
end
