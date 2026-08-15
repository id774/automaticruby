# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::AbsoluteURI
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 20, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterAbsoluteURI
    require 'uri'

    # Anything already carrying a scheme is left alone. The earlier spelling
    # of this test matched `http://` only, so an https link was treated as
    # relative and had the base prepended to it.
    ABSOLUTE = %r{\A[a-zA-Z][a-zA-Z0-9+.\-]*://}

    # URI::Parser became the RFC 3986 parser in Ruby 3.4, which reports #escape
    # as obsolete. The RFC 2396 parser is what this was always reaching and is
    # spelled the same way on every supported Ruby.
    ESCAPER = URI::RFC2396_Parser.new

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @base     = base_url
    end

    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil?

        feeds.items.each do |item|
          item.link = rewrite(item.link) unless item.link.nil?
        end
        returned << feeds
      end
    end

    private

    # Read once, in the constructor: the earlier version appended the trailing
    # slash to the Recipe's own config mapping, which is the plugin's input
    # rather than its state.
    def base_url
      url = @config['url'].to_s
      return url if url.empty? || url.end_with?('/')

      "#{url}/"
    end

    def rewrite(link)
      return link if ABSOLUTE.match?(link)

      ESCAPER.escape(@base + link.sub(/\A\./, '').sub(%r{\A/}, ''))
    end
  end
end
