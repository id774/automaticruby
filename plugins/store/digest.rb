# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Store::Digest
# Description:: Drop items whose content has been seen before, by SHA-256 digest.
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 17, 2026
# Updated::     Aug 17, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# Content identity, where StorePermalink is URL identity. The fields the Recipe
# names are normalized, joined into one canonical string and hashed, and the
# digest is what the database holds: an item whose digest is already there has
# been seen, whatever its link says, and an item whose link has been seen before
# under different content has not.
#
# It is exact matching, of the content the Recipe selected. Whitespace runs and
# Unicode composition differences are absorbed; nothing else is. Two articles
# that say the same thing in different words are two articles here, and making
# them one is not this plugin's work -- see doc/PLUGINS.md section 6.4.

require 'digest'
require_relative 'database'

module Automatic::Plugin
  # Named for what it holds rather than as `Digest`, which is Ruby's own
  # hashing module and is what computes the value stored here.
  class DigestRecord < ActiveRecord::Base
  end

  class StoreDigest
    include Automatic::Plugin::Database

    # The item fields a digest may be taken over. `date` is not one: an item
    # republished unchanged carries a new date often enough that including it
    # would defeat the purpose. `enclosure` is not one either, being a
    # structure rather than a value.
    FIELDS = %w[title link description author comments source content_encoded].freeze

    # What an item is, absent a Recipe saying otherwise: what it says, not
    # where it is. A feed that reissues an article under a new URL is the case
    # this plugin exists for.
    DEFAULT_FIELDS = %w[title description].freeze

    # The field name is part of what is hashed, and this separates it from its
    # value and one field from the next. A byte no title, body or URL contains,
    # so that no arrangement of two fields collides with another.
    SEPARATOR = "\0"

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    def column_definition
      { digest: :string, created_at: :string }
    end

    def model_class
      Automatic::Plugin::DigestRecord
    end

    # Records the digest of each item's selected fields and passes on only the
    # digests not already recorded.
    #
    # Nothing is rescued around the database. A store plugin that failed to
    # write and passed the item on anyway would publish it again on the next
    # run, which is the one thing this plugin is for.
    def run
      validate_settings
      prepare_database

      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil?

        new_items = feeds.items.select { |item| new_item?(item) }
        returned << Automatic::FeedMaker.create_pipeline(new_items) unless new_items.empty?
      end
    end

    private

    # The table the mixin builds, plus the constraint. Two runs of one Recipe
    # overlapping -- a `cron` entry that takes longer than its interval -- would
    # otherwise both read a digest as absent and both store it. The unique
    # index makes the second write fail instead, which #store below reads as
    # what it is.
    def create_table
      super
      ActiveRecord::Base.connection.add_index(model_class.table_name, :digest, unique: true)
    end

    # Everything the Recipe has to get right, checked before the database file
    # is opened. A Recipe this plugin cannot carry out is the operator's
    # mistake and will be the same mistake next hour.
    def validate_settings
      raise ArgumentError, 'StoreDigest needs a db file name' if @config['db'].to_s.strip.empty?

      fields
    end

    # The fields, in the order the Recipe wrote them. That order is part of the
    # fingerprint and is not sorted here: a Recipe that changes it has said
    # something different, and its digests are different digests.
    #
    # Only an absent `fields` takes the default. Every other way of getting it
    # wrong is refused rather than corrected, because a Recipe's own statement
    # of what makes two items the same is what this plugin has to obey.
    def fields
      @fields ||= validated_fields
    end

    def validated_fields
      given = @config['fields']
      return DEFAULT_FIELDS if given.nil?

      unless given.is_a?(Array)
        raise ArgumentError, "StoreDigest takes a list of fields, not #{given.inspect}"
      end

      names = given.map(&:to_s)
      raise ArgumentError, 'StoreDigest was given an empty fields list' if names.empty?

      unknown = names - FIELDS
      unless unknown.empty?
        raise ArgumentError,
              "StoreDigest cannot take a digest over #{unknown.join(', ')}; " \
              "the fields are #{FIELDS.join(', ')}"
      end

      duplicated = names.tally.select { |_name, count| count > 1 }.keys
      unless duplicated.empty?
        raise ArgumentError, "StoreDigest was given #{duplicated.join(', ')} twice"
      end

      names
    end

    # Whether the item goes downstream. An item whose digest was stored here is
    # new, one whose digest was already stored is not, and one there is nothing
    # to hash goes on unjudged.
    def new_item?(item)
      digest = digest_for(item)

      if digest.nil?
        Automatic::Log.puts('warn',
                            "StoreDigest: no digestable content for #{item.link}; " \
                            'passing item unchanged')
        return true
      end

      return false if stored_digest?(digest)

      store(digest, item)
    end

    def stored_digest?(digest)
      model_class.exists?(digest: digest)
    end

    # True when this run is the one that stored the digest. The read above
    # answers this on its own for a single run; the rescue is for the run
    # overlapping another, where the row appeared between the two statements.
    def store(digest, item)
      model_class.create!(digest: digest, created_at: Time.now.strftime('%Y/%m/%d %X'))
      Automatic::Log.puts('info', "Saving Digest: #{digest} (#{item.link})")
      true
    rescue ActiveRecord::RecordNotUnique
      false
    end

    # The digest of the item's selected fields, or nil where the Recipe
    # selected nothing the item has.
    #
    # An item with nothing to hash is not stored under the digest of the empty
    # string: every item with no description would then be the same item as
    # every other, and the first of them would silence the rest for good.
    def digest_for(item)
      values = fields.map { |field| [field, normalize(value_of(item, field))] }
      return nil if values.all? { |_field, value| value.empty? }

      canonical = values.map { |field, value| "#{field}#{SEPARATOR}#{value}" }.join(SEPARATOR)
      ::Digest::SHA256.hexdigest(canonical)
    end

    # A field an item does not carry reads as absent rather than raising.
    # `content_encoded` is the case that matters: an item built by a filter has
    # it, one straight from an RSS 2.0 feed may not.
    def value_of(item, field)
      item.respond_to?(field) ? item.public_send(field) : nil
    end

    # What two spellings of one string have to survive to hash alike: the
    # encoding, the composition of accented characters, and how much whitespace
    # a feed happens to have put between words. Nothing beyond that -- case,
    # punctuation and markup are content here, and an item that differs in them
    # is a different item.
    #
    # `scrub` is not redundant after `encode`: a conversion whose source and
    # destination encodings are the same is skipped, invalid bytes and all, and
    # `unicode_normalize` raises on what is left.
    def normalize(value)
      value.to_s.
        encode('UTF-8', invalid: :replace, undef: :replace).
        scrub.
        unicode_normalize(:nfc).
        gsub(/\s+/, ' ').
        strip
    end
  end
end
