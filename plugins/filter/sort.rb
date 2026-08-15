# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Sort
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar 23, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterSort
    def initialize(config, pipeline = [])
      @config    = config || {}
      @pipeline  = pipeline
      @ascending = @config['sort'].to_s == 'asc'
    end

    # Sorts each feed's items by date. Items must carry one; a feed built from
    # a source without dates fails here.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil?

        feeds.items.sort! { |a, b| @ascending ? a.date <=> b.date : b.date <=> a.date }
        returned << feeds
      end
    end
  end
end
