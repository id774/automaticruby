# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Sanitize
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 20, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterSanitize
    Automatic.require_optional('sanitize', needed_by: 'FilterSanitize')

    MODES = {
      'basic'   => Sanitize::Config::BASIC,
      'relaxed' => Sanitize::Config::RELAXED
    }.freeze

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @mode     = MODES.fetch(@config['mode'].to_s, Sanitize::Config::RESTRICTED)
    end

    # Strips HTML from descriptions.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil?

        feeds.items.each { |item| sanitize(item) }
        returned << feeds
      end
    end

    private

    def sanitize(item)
      item.description = Sanitize.fragment(item.description, @mode) unless item.description.nil?
    rescue StandardError => e
      Automatic::Log.puts('warn', "Undefined field detected in feed: #{e.message}")
    end
  end
end
