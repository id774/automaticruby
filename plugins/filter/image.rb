# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Image
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Sep 18, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterImage
    require 'uri'

    # webp and avif are here because they are what an image link on the
    # current web frequently is; tif joins tiff for the same reason.
    EXTENSIONS = /\.(jpe?g|gif|png|tiff?|webp|avif)\z/i

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Sets link to nil unless it names an image. Note that the items are kept:
    # their links are blanked, and the plugins after this one skip an item
    # whose link is nil.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil?

        feeds.items.each do |item|
          item.link = nil unless item.link.nil? || image?(item.link)
        end
        returned << feeds
      end
    end

    private

    # The test is on the path, so that a link carrying a query string -- which
    # is how an image is served by most of what serves images now -- is still
    # recognised. A string that will not parse is tested whole, as before.
    def image?(link)
      EXTENSIONS.match?(path(link))
    end

    def path(link)
      URI.parse(link).path.to_s
    rescue URI::InvalidURIError
      link
    end
  end
end
