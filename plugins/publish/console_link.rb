# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::ConsoleLink
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 02, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishConsoleLink
    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @output   = $stdout
    end

    # Prints each item's link, one per line, and nothing else. Useful in a
    # pipe, which is why an item whose link a filter has blanked prints
    # nothing rather than an empty line.
    def run
      @pipeline.each do |feeds|
        next if feeds.nil?

        feeds.items.each do |feed|
          @output.puts(feed.link) unless feed.link.nil?
        end
      end
      @pipeline
    end
  end
end
