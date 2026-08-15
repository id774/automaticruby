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

    SITEINFO_TYPES = %w[SBM INDIVIDUAL IND SUBGENERAL SUB GENERAL GEN].freeze

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
      entries = JSON.parse(File.read(File.join(assets_dir, name), encoding: 'UTF-8'))
      entries.select { |info| SITEINFO_TYPES.include?(info['data']['type']) }
             .sort_by { |info| SITEINFO_TYPES.index(info['data']['type']) }
    end

    def assets_dir
      dir = File.expand_path('~/.automatic/assets/siteinfo')
      return dir if File.directory?(dir)

      File.expand_path('../../assets/siteinfo', __dir__)
    end

    def fulltext(item)
      return if item.link.nil?

      info = @siteinfo.find { |entry| matches?(entry, item.link) }
      if info.nil?
        Automatic::Log.puts('info', "Fulltext SITEINFO not found: #{item.link}")
        return
      end

      Automatic::Log.puts('info', "Siteinfo matched: #{info['data']['url']}")
      item.description = body(item.link, info['data']['xpath'])
    rescue StandardError => e
      # An unreadable page leaves the item's own summary in place, which is
      # what this filter is an improvement on rather than a replacement for.
      Automatic::Log.puts('warn', "Failed to read fulltext for #{item.link}: #{e.message}")
    end

    def matches?(entry, link)
      link.match?(entry['data']['url'].to_s)
    rescue RegexpError
      false
    end

    def body(link, xpath)
      document = Nokogiri::HTML.parse(Automatic::Http.read(link))
      document.xpath(xpath).to_html.encode('UTF-8', undef: :replace)
    end
  end
end
