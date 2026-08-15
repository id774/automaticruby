# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Rand
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar  6, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterRand
    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Shuffles each feed's items. Combined with FilterOne, picks one at random.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil?

        returned << Automatic::FeedMaker.create_pipeline(feeds.items.shuffle)
      end
    end
  end
end
