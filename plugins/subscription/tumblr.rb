# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::Tumblr
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Oct 16, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class SubscriptionTumblr
    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Reads HTML written for a browser, so what it finds depends on the theme
    # a given blog uses. Verify against the blog you mean to follow before
    # putting it in cron, and set `interval`.
    def run
      Array(@config['urls']).each_with_object([]) do |url, feeds|
        pages(url).each do |page|
          rss = fetch(page, url)
          feeds << rss unless rss.nil?
        end
      end
    end

    private

    # The blog's own page, then /page/2 and onward.
    def pages(url)
      count = @config['pages'].to_i
      return [url] if count < 2

      [url] + (2..count).map { |number| "#{url}/page/#{number}" }
    end

    def fetch(url, blog_url)
      retries   = 0
      retry_max = @config['retry'].to_i
      begin
        Automatic::Log.puts('info', "Parsing Tumblr: #{url}")
        rss = Automatic::FeedParser.parse_html(Automatic::Http.read(url))
        drop_offsite_links(rss, blog_url)
        sleep(@config['interval'].to_i)
        rss
      rescue StandardError => e
        retries += 1
        Automatic::Log.puts('error',
                            "ErrorCount: #{retries}, Fault in parsing: #{url}, #{e.message}")
        return nil if retries > retry_max

        sleep(@config['interval'].to_i)
        retry
      end
    end

    # A theme's page carries the blog's own posts and a great deal else. A
    # link that leaves the blog's host is blanked rather than removed, which
    # is the pipeline's way of saying "not applicable"; the plugins after this
    # one skip an item whose link is nil.
    def drop_offsite_links(rss, blog_url)
      host = Automatic::Http.uri(blog_url).host.to_s
      rss.items.each do |item|
        item.link = nil unless item.link.to_s.include?(host)
      end
    end
  end
end
