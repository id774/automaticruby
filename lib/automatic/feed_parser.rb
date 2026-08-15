# -*- coding: utf-8 -*-
# Name::        Automatic::FeedParser
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 19, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# Fetching and parsing, on the way into the pipeline. What leaves here has the
# shape described in doc/PLUGINS.md section 3.4.

module Automatic
  module FeedParser
    require 'rss'
    require 'automatic/http'

    # Fetch a URL and parse it as a feed. Validation is off, because feeds in
    # the wild frequently are not valid and are still readable.
    #
    # Fetching goes through Automatic::Http, which is where the scheme
    # allowlist, the timeouts and the redirect limit live.
    def self.get_url(url)
      return if url.nil?

      Automatic::Log.puts('info', "Parsing Feed: #{url}")
      RSS::Parser.parse(Automatic::Http.read(url), false)
    end

    # Build a feed whose items are the links of an HTML document. This is how
    # a page that publishes no feed enters the pipeline.
    #
    # nokogiri is required here rather than at the top of the file: it is the
    # only thing in the framework that wants an HTML parser, it is an optional
    # dependency rather than a runtime one, and requiring `automatic` must
    # neither load one nor need one installed. Only the plugins that call this
    # method -- SubscriptionLink and SubscriptionTumblr -- do.
    # See doc/POLICY.md sections 2.5 and 9.1.
    def self.parse_html(html)
      Automatic.require_optional(
        'nokogiri',
        needed_by: 'Automatic::FeedParser.parse_html, used by SubscriptionLink ' \
                   'and SubscriptionTumblr'
      )

      RSS::Maker.make('2.0') do |maker|
        maker.xml_stylesheets.new_xml_stylesheet
        maker.channel.title = 'Automatic Ruby'
        maker.channel.description = 'Automatic::FeedParser'
        maker.channel.link = 'https://github.com/id774/automaticruby'
        maker.items.do_sort = true

        doc = Nokogiri::HTML(html)
        (doc / :a).each do |link|
          next if link[:href].nil?

          item = maker.items.new_item
          item.title = 'Automatic Ruby'
          item.link = link[:href]
          item.date = Time.now
          item.description = ''
        end
      end
    end
  end
end
