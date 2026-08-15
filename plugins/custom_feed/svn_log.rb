# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::CustomFeed::SVNLog
# Author:       kzgs
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 29, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require 'rexml/document'
require 'rss/maker'
require 'time'

module Automatic::Plugin
  class CustomFeedSVNLog
    DEFAULT_FETCH_ITEMS = 30

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    def run
      entries = revisions
      if entries.empty?
        # RSS 1.0 has no representation for a channel with no items, and a
        # repository with no revisions in the window asked for is an ordinary
        # answer rather than a failure.
        Automatic::Log.puts('warn', "No revisions returned by svn log for #{base_url}")
        return @pipeline
      end

      @pipeline << feed(entries)
      @pipeline
    end

    private

    def feed(revisions)
      RSS::Maker.make('1.0') do |maker|
        maker.channel.title       = @config['title'].to_s
        maker.channel.about       = ''
        maker.channel.description = ''
        maker.channel.link        = base_url

        revisions.each do |revision|
          item       = maker.items.new_item
          item.title = "#{revision['msg']} by #{revision['author']}"
          item.link  = "#{base_url}/!svn/bc/#{revision['revision']}"
          item.date  = Time.parse(revision['date'])
        end
      end
    end

    # `svn log --xml` as REXML sees it. REXML is a runtime dependency of this
    # framework already -- the OPML parser uses it -- so this plugin needs the
    # svn command and no gem of its own.
    def revisions
      REXML::Document.new(svn_log).elements.to_a('/log/logentry').map do |entry|
        {
          'revision' => entry.attributes['revision'].to_s,
          'author'   => text(entry, 'author'),
          'msg'      => text(entry, 'msg'),
          'date'     => text(entry, 'date')
        }
      end
    end

    def text(entry, name)
      element = entry.elements[name]
      element.nil? ? '' : element.text.to_s
    end

    # The command is run as an argument vector rather than through a shell, so
    # a repository URL cannot become part of a command line. Point `target` at
    # a repository you control regardless: svn itself will do what the URL
    # tells it to.
    def svn_log
      output = IO.popen(['svn', 'log', base_url, '--xml', "--limit=#{limit}"],
                        err: File::NULL, &:read)
      raise "svn log failed for #{base_url}" unless $?.success?

      output
    end

    def base_url
      @base_url ||= @config['target'].to_s.sub(%r{/\z}, '')
    end

    def limit
      value = @config['fetch_items'].to_i
      value.positive? ? value : DEFAULT_FETCH_ITEMS
    end
  end
end
