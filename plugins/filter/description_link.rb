# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::DescriptionLink
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Oct 03, 2014
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterDescriptionLink
    Automatic.require_optional('nokogiri', needed_by: 'FilterDescriptionLink')
    require 'uri'

    # URI.extract and URI::PATTERN answer through the RFC 3986 parser that
    # URI::Parser became in Ruby 3.4, which reports both as obsolete. The RFC
    # 2396 parser is what they were always reaching, it is spelled the same way
    # on every supported Ruby, and it is named here directly.
    PARSER = URI::RFC2396_Parser.new

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Takes the last HTTP or HTTPS URL out of the description and makes it the
    # link, for feeds that carry the real destination in the body.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        items = feeds.nil? ? [] : feeds.items.map { |item| rewrite(item) }
        returned << Automatic::FeedMaker.create_pipeline(items)
      end
    end

    private

    def rewrite(item)
      link = PARSER.extract(item.description.to_s, %w[http https]).uniq.last
      item.link = link unless link.nil?

      item.description = '' if setting?('clear_description')
      retitle(item) if setting?('get_title')

      item
    end

    # Settings are read whatever the mapping is. This tested `@config.class ==
    # Hash`, which a Recipe never satisfies: the framework hands a plugin a
    # Hashie::Mash, so both settings below were silently ignored in every real
    # run and read only by a spec passing a plain Hash.
    def setting?(name)
      @config[name].to_s == '1'
    end

    def retitle(item)
      title = fetch_title(item.link)
      item.title = title unless title.nil? || title.empty?
    end

    # One request per item; use FilterOne or a store plugin before this on a
    # large feed. A page that cannot be read leaves the item's own title.
    def fetch_title(url)
      return nil unless Automatic::Http.fetchable?(url)

      Nokogiri::HTML.parse(Automatic::Http.read(url)).xpath('//title').text
    rescue StandardError => e
      Automatic::Log.puts('warn', "Failed in get title for: #{url}, #{e.message}")
      nil
    end
  end
end
