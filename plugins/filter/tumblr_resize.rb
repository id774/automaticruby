# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::TumblrResize
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 28, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterTumblrResize
    # Tumblr has served images under two URL schemes. The older one carries
    # the size as a suffix on the file name -- tumblr_xxx_500.jpg -- and is
    # what images uploaded before 2019 still use. The newer one carries it as
    # a path segment -- /s540x810/ -- and is what everything since uses.
    # Both are rewritten to the largest variant the scheme offers.
    LEGACY_SIZE = /_(?:75sq|100|250|400|500)(?=\.[a-zA-Z0-9]+\z)/
    LEGACY_LARGEST = '_1280'

    PATH_SIZE = %r{/s\d+x\d+/}
    PATH_LARGEST = '/s1280x1920/'

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Assumes FilterImage or FilterImageSource has already put an image URL in
    # the link.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        unless feeds.nil?
          feeds.items.each do |item|
            item.link = resize(item.link) unless item.link.nil?
          end
        end
        returned << feeds
      end
    end

    private

    def resize(link)
      link.sub(LEGACY_SIZE, LEGACY_LARGEST).sub(PATH_SIZE, PATH_LARGEST)
    end
  end
end
