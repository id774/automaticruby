# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::One
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     May  8, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterOne
    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @last     = @config['pick'].to_s == 'last'
    end

    # Reduces each feed to a single item. A feed that has none is dropped
    # rather than reduced to one nil.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil? || feeds.items.empty?

        item = @last ? feeds.items.last : feeds.items.first
        returned << Automatic::FeedMaker.create_pipeline([item])
      end
    end
  end
end
