# -*- coding: utf-8 -*-
# Name::        Automatic::Http
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 15, 2026
# Updated::     Aug 21, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# One way in for everything the plugins fetch over HTTP.
#
# This exists because seven plugins were each calling `URI.open` on a string,
# and the four decisions that call implies -- which schemes are allowed, how
# long to wait, how many redirects to follow, what to send as a User-Agent --
# were being made seven times, mostly by omission. They are made once here.
# It is a helper, not a client framework: one method fetches, one builds a URI,
# and a plugin that wants something else still calls Ruby directly.
# See doc/POLICY.md section 9.2 and doc/PLUGINS.md section 3.8.

require 'open-uri'
require 'uri'
require 'automatic/version'

module Automatic
  module Http
    # A link in a pipeline item comes from a feed, which is to say from
    # outside. `URI.open` on such a string will happily read `file:///etc/passwd`
    # or run an FTP session; a plugin fetching an article body wants neither.
    SCHEMES = %w[http https].freeze

    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30

    # open-uri follows redirects itself and refuses an HTTPS-to-HTTP downgrade.
    # This bounds the chain so that a redirect loop ends as an error rather
    # than as an unattended run that never returns.
    REDIRECT_LIMIT = 5

    USER_AGENT = "Automatic Ruby/#{Automatic::VERSION} " \
                 '(+https://github.com/id774/automaticruby)'

    # The RFC 2396 parser is named directly: `URI.escape` was removed in Ruby
    # 3.0, and `URI::Parser` became the RFC 3986 parser in 3.4, which reports
    # #escape as obsolete. This spelling means the same thing on every
    # supported Ruby.
    ESCAPER = URI::RFC2396_Parser.new

    class << self
      # Fetch a URL and return its body as a string. Raises rather than
      # returning nil: a plugin's retry handling is built around an exception,
      # and a body that could not be fetched is not an empty body.
      def read(url)
        open(url, &:read)
      end

      # Fetch a URL and yield the IO, for a caller that would rather stream
      # than hold the whole body.
      def open(url, &block)
        uri(url).open(
          'User-Agent' => USER_AGENT,
          open_timeout: OPEN_TIMEOUT,
          read_timeout: READ_TIMEOUT,
          redirect: true,
          max_redirects: REDIRECT_LIMIT,
          &block
        )
      end

      # Parse a URL into a URI this framework will fetch, or raise. A string
      # carrying characters a URI may not (a space, a Japanese query term) is
      # escaped and parsed again, which is what the plugins used to do for
      # themselves before every call.
      def uri(url)
        string = url.to_s.strip
        raise ArgumentError, 'no URL to fetch' if string.empty?

        parsed = parse(string)
        unless SCHEMES.include?(parsed.scheme)
          raise ArgumentError, "not an HTTP or HTTPS URL: #{string}"
        end
        unless parsed.host
          raise ArgumentError, "HTTP or HTTPS URL has no host: #{string}"
        end

        parsed.normalize
      end

      # Whether a string is a URL this framework will fetch. For a plugin that
      # skips an item rather than failing the run on one.
      def fetchable?(url)
        uri(url)
        true
      rescue ArgumentError, URI::InvalidURIError
        false
      end

      private

      def parse(string)
        URI.parse(string)
      rescue URI::InvalidURIError
        URI.parse(ESCAPER.escape(string))
      end
    end
  end
end
