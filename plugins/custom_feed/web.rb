# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::CustomFeed::Web
# Description:: Build a feed from the article links of an HTML index page.
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 17, 2026
# Updated::     Aug 17, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# One page in, one feed out. The pages named in the Recipe are fetched, their
# article links are taken with CSS selectors, and each page becomes a feed of
# what it currently lists. Nothing else is fetched: the links are not
# followed, no article body is read, and no page beyond the ones named is
# visited, so a run costs one request per site.
#
# It keeps no state of its own, deliberately. What was published last time is
# StorePermalink's question, and the Recipe that answers it puts StorePermalink
# after this plugin. See doc/PLUGINS.md section 6.2.

require 'rss/maker'
require 'set'
require 'time'
require 'uri'

module Automatic::Plugin
  class CustomFeedWeb
    Automatic.require_optional('nokogiri', needed_by: 'CustomFeedWeb')

    DEFAULT_FETCH_ITEMS = 100

    # What an article link is, where the Recipe does not say. Every mode ends
    # at an `<a href>`, because a permalink is what a feed item needs.
    DEFAULT_LINK_SELECTOR = 'a[href]'

    # A link in a page is written by whoever wrote the page. `mailto:`,
    # `javascript:` and `file:` links are ordinary in a navigation bar and are
    # not articles.
    SCHEMES = %w[http https].freeze

    # One article as the page presents it, before it becomes an item. Internal
    # to this plugin: what leaves here is the pipeline value of section 3.4.
    Candidate = Struct.new(:title, :url, :description, :date, keyword_init: true)

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @seen     = Set.new
    end

    def run
      sites.each do |site|
        feed = feed_for(site)
        @pipeline << feed unless feed.nil?
      end
      @pipeline
    end

    private

    # Every site, checked before anything is fetched.
    #
    # A Recipe this plugin cannot carry out -- a site that is not a mapping, a
    # URL that cannot be fetched, a pattern that is not a regular expression,
    # a selector combination that names no article -- is the operator's
    # mistake, and it will be the same mistake after a retry and a wait. It is
    # refused here, where no request has been made yet, rather than inside the
    # retry loop, which is for a host that did not answer.
    def sites
      @sites ||= Array(@config['sites']).each { |site| validate(site) }
    end

    def validate(site)
      unless site.is_a?(Hash)
        raise ArgumentError,
              'CustomFeedWeb takes a mapping with a url key for each site, ' \
              "not #{site.inspect}"
      end

      source(site)
      patterns(site, 'include')
      patterns(site, 'exclude')
      article_unit(site)
    end

    # The page URL as this plugin will fetch and resolve against it.
    # Automatic::Http is what says which URLs those are.
    def source(site)
      Automatic::Http.uri(site['url'])
    rescue ArgumentError, URI::InvalidURIError => e
      raise ArgumentError, "CustomFeedWeb needs a url for each site: #{e.message}"
    end

    def patterns(site, key)
      Array(site[key]).map { |pattern| Regexp.new(pattern.to_s) }
    rescue RegexpError => e
      raise ArgumentError,
            "CustomFeedWeb was given an invalid #{key} pattern for " \
            "#{site['url']}: #{e.message}"
    end

    # `title_selector`, `description_selector` and `date_selector` are read
    # inside one article's node, and `item_selector` is what says where an
    # article begins and ends. Without it there is no node to read them in,
    # and a page of anchors cannot be divided into articles by guessing.
    def article_unit(site)
      return if presence(site['item_selector'])

      named = %w[title_selector description_selector date_selector].
              select { |key| presence(site[key]) }
      return if named.empty?

      raise ArgumentError,
            "CustomFeedWeb needs item_selector to use #{named.join(', ')}: " \
            "#{site['url']}"
    end

    def feed_for(site)
      base     = source(site)
      document = fetch(site)
      return nil if document.nil?

      articles = entries(document, site, base)
      if articles.empty?
        # A list page with nothing on it that this Recipe recognises is an
        # ordinary answer rather than a failure, and an empty feed would only
        # give the rest of the pipeline something to skip.
        Automatic::Log.puts('warn', "No article links found on #{base}")
        return nil
      end

      Automatic::Log.puts('info', "Web feed: #{articles.size} items from #{base}")
      feed(site, document, base, articles)
    end

    # The page, or nil where it could not be read after its retries. One site
    # that is down does not take the rest of the Recipe with it.
    #
    # The parser is given the stream rather than a decoded string, so that it
    # reads the document's own meta charset instead of the encoding open-uri
    # settled on. See doc/PLUGINS.md section 3.8.1.
    def fetch(site)
      url       = site['url']
      retries   = 0
      retry_max = @config['retry'].to_i
      begin
        Automatic::Log.puts('info', "Parsing Web page: #{url}")
        document = Automatic::Http.open(url) { |io| Nokogiri::HTML(io) }
        sleep(@config['interval'].to_i)
        document
      rescue StandardError => e
        retries += 1
        Automatic::Log.puts('error',
                            "ErrorCount: #{retries}, Fault in fetching: #{url}, #{e.message}")
        if retries > retry_max
          Automatic::Log.puts('warn', "Skipping #{url}")
          return nil
        end

        sleep(@config['interval'].to_i)
        retry
      end
    end

    # The candidates that survive, in the order the page lists them, up to
    # `fetch_items`. A list page's own order is the only ordering information
    # it carries, so nothing here sorts.
    def entries(document, site, base)
      includes = patterns(site, 'include')
      excludes = patterns(site, 'exclude')
      limit    = fetch_items(site)

      candidates(document, site).each_with_object([]) do |candidate, kept|
        next if candidate.title.empty?

        url = permalink(candidate.url, base, site, includes, excludes)
        next if url.nil?

        candidate.url = url
        kept << candidate
        break kept if kept.size >= limit
      end
    end

    # The three ways a page is read, and the only three: every anchor, the
    # anchors a selector names, or an article node with its parts inside it.
    def candidates(document, site)
      item_selector = presence(site['item_selector'])
      return anchors(document, site) if item_selector.nil?

      document.css(item_selector).filter_map { |node| article(node, site) }
    end

    def anchors(document, site)
      selector = presence(site['link_selector']) || DEFAULT_LINK_SELECTOR
      document.css(selector).filter_map { |node|
        next if node['href'].nil?

        Candidate.new(title: normalize(node.text), url: node['href'], description: '')
      }
    end

    def article(node, site)
      link = node.at_css(presence(site['link_selector']) || DEFAULT_LINK_SELECTOR)
      return nil if link.nil? || link['href'].nil?

      Candidate.new(
        title:       title(node, site, link),
        url:         link['href'],
        description: description(node, site),
        date:        date(node, site)
      )
    end

    # A `title_selector` that selects nothing in this particular article falls
    # back to the link's own text rather than dropping the article: one entry
    # laid out differently from the rest of a list is ordinary.
    def title(node, site, link)
      selector = presence(site['title_selector'])
      found    = selector.nil? ? nil : node.at_css(selector)
      normalize((found || link).text)
    end

    # The summary the list page prints, as text. Not the article: this plugin
    # does not fetch one.
    def description(node, site)
      selector = presence(site['description_selector'])
      return '' if selector.nil?

      found = node.at_css(selector)
      found.nil? ? '' : normalize(found.text)
    end

    # `<time datetime="2026-08-17T09:00:00+09:00">yesterday</time>` is the
    # reason the attribute is preferred: it is written for a machine, and the
    # text beside it is written for a reader.
    def date(node, site)
      selector = presence(site['date_selector'])
      return nil if selector.nil?

      found = node.at_css(selector)
      return nil if found.nil?

      published(found.name == 'time' && found['datetime'] ? found['datetime'] : found.text)
    end

    # A date that cannot be read costs the article its date and not its place
    # in the feed. Nothing is substituted for it: the time this ran is when
    # the page was fetched, which is not when the article was published.
    def published(value)
      Time.parse(value.to_s)
    rescue ArgumentError => e
      Automatic::Log.puts('warn', "Unreadable date #{value.to_s.strip.inspect}: #{e.message}")
      nil
    end

    # The judgements a candidate URL passes, in this order: it is resolved
    # against the page it was found on, then it is one this framework fetches,
    # then it is not the page itself, then the host, then include, then
    # exclude, and only what has survived all of them is recorded as seen.
    def permalink(href, base, site, includes, excludes)
      uri = absolute(href, base)
      return nil if uri.nil? || !SCHEMES.include?(uri.scheme)

      url = uri.to_s
      return nil if url == base.to_s
      return nil if same_host?(site) && !same_host_as?(uri, base)
      return nil if includes.any? && includes.none? { |pattern| pattern.match?(url) }
      return nil if excludes.any? { |pattern| pattern.match?(url) }

      # Within one run only. Whether a URL was published last week is
      # StorePermalink's record, not this plugin's.
      @seen.add?(url).nil? ? nil : url
    end

    # Resolved against the page it was found on, so that `/articles/42`,
    # `../42` and `//example.com/42` all become the URL a reader would follow.
    # The fragment goes, because two links differing only in their anchor are
    # one article. The query string stays, because `?id=42` is frequently the
    # whole of what identifies one, and no canonical form is guessed.
    def absolute(href, base)
      uri = base.merge(href.to_s.strip)
      uri.fragment = nil
      uri
    rescue URI::Error, ArgumentError
      nil
    end

    def same_host?(site)
      value = site['same_host']
      value.nil? ? true : value
    end

    # An exact host match, and nothing cleverer. `www.example.com` and
    # `blog.example.com` are one organisation and are not one site, and which
    # of them a Recipe wants is the Recipe's to say.
    def same_host_as?(uri, base)
      uri.host.to_s.downcase == base.host.to_s.downcase
    end

    def fetch_items(site)
      value = site['fetch_items'].to_i
      value.positive? ? value : DEFAULT_FETCH_ITEMS
    end

    def feed(site, document, base, entries)
      RSS::Maker.make('2.0') do |maker|
        maker.channel.title       = channel_title(site, document, base)
        maker.channel.link        = base.to_s
        maker.channel.description = "Web page items from #{base}"
        # The page's order is kept. RSS::Maker sorts its items by date when it
        # is asked to, and an article the page listed first is first for a
        # reason a date does not carry.
        maker.items.do_sort = false

        entries.each do |entry|
          item             = maker.items.new_item
          item.title       = entry.title
          item.link        = entry.url
          item.description = entry.description
          item.date        = entry.date unless entry.date.nil?
        end
      end
    end

    # `name`, then what the page calls itself, then the host it came from.
    def channel_title(site, document, base)
      name = presence(site['name'])
      return name unless name.nil?

      title = normalize(document.title.to_s)
      title.empty? ? base.host.to_s : title
    end

    # "  Ruby\n   4.0\t released  " is "Ruby 4.0 released". A title in a list
    # page is laid out for a browser, and the line breaks and indentation of
    # the markup are not part of it.
    def normalize(text)
      text.to_s.gsub(/[[:space:]]+/, ' ').strip
    end

    def presence(value)
      string = value.to_s.strip
      string.empty? ? nil : string
    end
  end
end
