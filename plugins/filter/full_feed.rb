# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::FullFeed
# Author:       progd (More info: http://d.hatena.ne.jp/progd/20120429/automatic_ruby_filter_full_feed)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Apr 29, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterFullFeed
    Automatic.require_optional('nokogiri', needed_by: 'FilterFullFeed')
    require 'json'
    require 'stringio'

    SITEINFO_TYPES = %w[SBM INDIVIDUAL IND SUBGENERAL SUB GENERAL GEN].freeze

    # One siteinfo record, reduced to the four things a match needs and with
    # its URL pattern compiled once. The database ships with 3,504 usable
    # records, so compiling them per item -- which is what matching against
    # the raw JSON did -- was several thousand `Regexp.new` calls for every
    # link in every feed.
    Entry = Struct.new(:url, :pattern, :xpath, :encoding)

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @siteinfo = siteinfo
    end

    # Replaces a summary with the article body, by matching the link against a
    # siteinfo database of URL patterns and XPaths and fetching the page.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        unless feeds.nil?
          feeds.items.each { |item| fulltext(item) }
        end
        returned << feeds
      end
    end

    private

    def siteinfo
      name = @config['siteinfo'].to_s
      raise ArgumentError, 'FilterFullFeed needs a siteinfo file name' if name.empty?

      Automatic::Log.puts('info', "Loading siteinfo from #{name}")
      records = JSON.parse(File.read(File.join(assets_dir, name), encoding: 'UTF-8'))
      entries = records.select { |info| SITEINFO_TYPES.include?(info['data']['type']) }
                       .sort_by { |info| SITEINFO_TYPES.index(info['data']['type']) }
                       .filter_map { |info| entry(info['data']) }
      Automatic::Log.puts('info', "Loaded #{entries.size} siteinfo entries")
      entries
    end

    # A record is dropped here rather than failing a match later. A record
    # without a URL pattern would match every link -- an empty pattern matches
    # everything -- and one without an XPath has nothing to select with.
    def entry(data)
      url   = data['url'].to_s
      xpath = data['xpath'].to_s.strip
      return nil if url.empty? || xpath.empty?

      Entry.new(url, Regexp.new(url), xpath, charset(data['enc']))
    rescue RegexpError
      nil
    end

    def assets_dir
      dir = File.expand_path('~/.automatic/assets/siteinfo')
      return dir if File.directory?(dir)

      File.expand_path('../../assets/siteinfo', __dir__)
    end

    def fulltext(item)
      return if item.link.nil?

      record = match(item.link)
      if record.nil?
        Automatic::Log.puts('info', "Fulltext SITEINFO not found: #{item.link}")
        return
      end

      Automatic::Log.puts('info', "Siteinfo matched: #{record.url}")
      html = body(item.link, record)
      if html.nil?
        # The page was read but the XPath selected nothing, which is what a
        # site that has been redesigned since its record was written looks
        # like. Assigning the empty result here is what used to replace a
        # perfectly good summary with an empty description.
        Automatic::Log.puts('warn', "Fulltext XPath selected nothing on #{item.link}: #{record.xpath}")
        return
      end

      item.description = html
    rescue StandardError => e
      # An unreadable page leaves the item's own summary in place, which is
      # what this filter is an improvement on rather than a replacement for.
      Automatic::Log.puts('warn', "Failed to read fulltext for #{item.link}: #{e.message}")
    end

    def match(link)
      links = schemes(link)
      @siteinfo.find { |record| links.any? { |candidate| record.pattern.match?(candidate) } }
    end

    # The database was last updated in 2013 and 3,448 of its 3,504 records
    # anchor on a scheme, nearly all of them `^http://`. The sites they name
    # have since moved to HTTPS, so an https link out of a feed matches none of
    # them and the filter silently does nothing. Matching the link under either
    # scheme is what keeps those records reachable; a record is about a site's
    # layout, not about how it is transported. Only the match is rewritten --
    # the page is fetched from the link the feed gave.
    def schemes(link)
      case link
      when %r{\Ahttps://} then [link, link.sub(%r{\Ahttps://}, 'http://')]
      when %r{\Ahttp://}  then [link, link.sub(%r{\Ahttp://}, 'https://')]
      else [link]
      end
    end

    # Returns the selected body as UTF-8, or nil when the XPath selects
    # nothing, so that the caller can tell an article apart from an empty
    # result and keep the summary it already had.
    def body(link, entry)
      nodes = document(link, entry).xpath(entry.xpath)
      return nil if nodes.empty?

      # Normalised to UTF-8, and scrubbed rather than raised on. The parser
      # returns a string in whatever encoding it settled on for the page, and
      # a page whose declared charset is not the one it is written in is
      # common enough in a database this old; what leaves here goes on to a
      # publish plugin, which has no way to recover from a string it cannot
      # encode. `invalid:` as well as `undef:`, because converting UTF-8 to
      # UTF-8 leaves invalid bytes alone unless they are named.
      html = nodes.to_html.encode('UTF-8', invalid: :replace, undef: :replace)
      html.strip.empty? ? nil : html
    end

    # Read the page and parse it under the encoding it is actually written in.
    #
    # The page is handed to the parser as a stream rather than as a decoded
    # string. open-uri applies an encoding to what it returns whether or not
    # the response declared one -- a page served as `text/html` with no charset
    # comes back tagged UTF-8 -- and a decoded string tells the parser to
    # believe that tag and never look at the meta tag underneath it. The
    # database is full of sites that declare their charset only in a meta tag,
    # and for those the difference is the whole article in mojibake.
    #
    # A record's own `enc` is the last resort, for a page that declares nothing
    # anywhere: it was recorded in 2013, and trusting it ahead of what the page
    # says would break every site that has changed encoding since.
    def document(link, entry)
      page, declared = Automatic::Http.open(link) { |io| [io.read, declared_charset?(io)] }
      parsed = Nokogiri::HTML.parse(StringIO.new(page))
      return parsed if declared || parsed.meta_encoding || entry.encoding.nil?

      Nokogiri::HTML.parse(StringIO.new(page), nil, entry.encoding)
    end

    # Whether the response itself named a charset, as opposed to open-uri
    # having settled on one in the absence of an answer.
    def declared_charset?(io)
      return false unless io.respond_to?(:meta)

      io.meta['content-type'].to_s.match?(/;\s*charset\s*=/i)
    end

    # An encoding named by a siteinfo record. An unknown name is ignored rather
    # than raised, and the page is left to speak for itself.
    def charset(name)
      string = name.to_s.strip
      return nil if string.empty?

      Encoding.find(string).name
    rescue ArgumentError
      nil
    end
  end
end
