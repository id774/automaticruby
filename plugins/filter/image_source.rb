# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::ImageSource
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 28, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterImageSource
    Automatic.require_optional('nokogiri', needed_by: 'FilterImageSource')
    require 'uri'

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Replaces each item with one item per image found: the images in the
    # description, or, where it has none, the images on the page the link
    # points at. The second case reaches the network.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        items = feeds.nil? ? [] : feeds.items.flat_map { |item| extract(item) }
        returned << Automatic::FeedMaker.create_pipeline(items)
      end
    end

    private

    def extract(item)
      images(item).map do |link|
        Automatic::Log.puts('info', "Extract Image: #{link}")
        image = Hashie::Mash.new
        image.title = 'FilterImageSource'
        image.link  = link
        image
      end
    end

    def images(item)
      found = sources(item.description.to_s, item.link)
      return found unless found.empty?
      return [] if item.link.nil?

      page_images(item.link)
    end

    def page_images(link)
      sources(Automatic::Http.read(link), link)
    rescue StandardError => e
      Automatic::Log.puts('warn', "Failed to read images from #{link}: #{e.message}")
      []
    end

    # The images of an HTML fragment, as absolute URLs. This was a scan for
    # `<img src="` before, which found nothing in a document quoting its
    # attributes with apostrophes or writing src after another attribute; the
    # parser this plugin already needs answers the question properly.
    def sources(html, base)
      Nokogiri::HTML.fragment(html).css('img').filter_map do |image|
        source = image['src'].to_s.strip
        absolute(source, base) unless source.empty?
      end.uniq
    end

    def absolute(source, base)
      return source if base.nil?

      URI.join(base, source).to_s
    rescue StandardError
      source
    end
  end
end
