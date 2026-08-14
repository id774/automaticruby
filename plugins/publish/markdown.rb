# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Markdown
# Description:: Render the pipeline as a Markdown document, to a file or to standard output.
# Author::    774 <http://id774.net>
# Created::   Aug 14, 2026
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishMarkdown
    require 'fileutils'
    require 'nokogiri'

    # Written under an item's heading, in this order. A field the item does not
    # carry produces no bullet at all, so an item is not padded out with empty
    # ones. See doc/PLUGINS.md section 6.7.
    METADATA_FIELDS = [
      ['Link',      :link],
      ['Date',      :date],
      ['Author',    :author],
      ['Comments',  :comments],
      ['Source',    :source],
      ['Enclosure', :enclosure]
    ].freeze

    # Elements that end a line of text. Everything else is unwrapped: the body
    # is reduced to text rather than translated into Markdown, because doing
    # the latter properly needs a library this framework declines to depend on.
    BLOCK_ELEMENTS = %w[
      address article aside blockquote dd div dl dt figcaption figure footer
      form h1 h2 h3 h4 h5 h6 header hr li main nav ol p pre section table
      tbody td th thead tr ul
    ].freeze

    # A body counts as HTML when it carries a tag or a character entity. One
    # that carries neither is written as it stands, so that a "<" in a
    # plain-text description is not parsed away.
    MARKUP = %r{<[a-zA-Z/!]|&[a-zA-Z#][0-9a-zA-Z]*;}

    # The item's own date, in the zone the item carries. Nothing is converted
    # to local time: the same pipeline then produces the same document
    # wherever it runs.
    DATE_FORMAT = '%Y-%m-%d %H:%M:%S %z'

    UNTITLED = '(untitled)'

    def initialize(config, pipeline=[])
      @config   = config || {}
      @pipeline = pipeline
      @output   = $stdout
      @file     = @config['file'].nil? ? nil : File.expand_path(@config['file'].to_s)
      @mode     = @config['mode'] == 'overwrite' ? 'w' : 'a'
    end

    def run
      sections = render
      write(sections) unless sections.empty?
      @pipeline
    end

    private

    def render
      sections = []
      @pipeline.each {|feeds|
        next if feeds.nil?

        feeds.items.each {|feed|
          sections << section(feed)
        }
      }
      sections
    end

    # Heading, then the metadata list, then the body, each separated by a blank
    # line and the whole followed by one. Appending a document to a document is
    # then still a Markdown document.
    def section(feed)
      parts = ["## #{heading(feed)}\n"]
      metadata = metadata_list(feed)
      parts << metadata unless metadata.empty?
      body = body_text(feed)
      parts << body unless body.empty?
      parts.join("\n") + "\n"
    end

    def heading(feed)
      title = one_line(value(feed, :title))
      return title unless title.empty?

      link = one_line(value(feed, :link))
      link.empty? ? UNTITLED : link
    end

    def metadata_list(feed)
      METADATA_FIELDS.map {|label, name|
        text = name == :date ? date(feed) : one_line(value(feed, name))
        next if text.empty?

        "- #{label}: #{url?(text) ? "<#{text}>" : text}\n"
      }.compact.join
    end

    # content_encoded when the item has one and description otherwise: a feed
    # carrying both puts the summary in the second and the article in the first.
    def body_text(feed)
      text = value(feed, :content_encoded)
      text = value(feed, :description) if text.empty?
      MARKUP.match?(text) ? normalize(html_to_text(text), true) : normalize(text, false)
    end

    def date(feed)
      field = feed.respond_to?(:date) ? feed.date : nil
      return '' if field.nil?

      field.respond_to?(:strftime) ? field.strftime(DATE_FORMAT) : one_line(field.to_s)
    end

    # Any field may be absent, and a parsed feed answers with an element rather
    # than a string where the format has one: a source carries its text in
    # #content, an enclosure its URL in #url.
    def value(feed, name)
      return '' unless feed.respond_to?(name)

      field = feed.send(name)
      return '' if field.nil?

      if field.respond_to?(:content)
        field.content.to_s.strip
      elsif field.respond_to?(:url)
        field.url.to_s.strip
      else
        field.to_s.strip
      end
    end

    def one_line(text)
      text.gsub(/\s+/, ' ').strip
    end

    def url?(text)
      text.match?(%r{\A[a-zA-Z][a-zA-Z0-9+.-]*://\S+\z})
    end

    # Reduce markup to text: script and style go with their contents, a break
    # ends a line, a block element ends a paragraph, entities are decoded by
    # the parser, and the tags themselves are dropped.
    def html_to_text(html)
      fragment = Nokogiri::HTML.fragment(html)
      fragment.css('script, style').each {|node| node.remove }
      fragment.css('br').each {|node| node.replace(text_node(node, "\n")) }
      fragment.css(BLOCK_ELEMENTS.join(', ')).each {|node|
        node.add_previous_sibling(text_node(node, "\n"))
        node.add_next_sibling(text_node(node, "\n\n"))
      }
      fragment.text
    end

    def text_node(node, text)
      Nokogiri::XML::Text.new(text, node.document)
    end

    # Line endings become "\n", trailing whitespace goes, and a run of blank
    # lines collapses to one. Text that came from markup also loses the
    # source's own indentation, which is layout rather than content and which
    # Markdown would otherwise read as a code block.
    def normalize(text, from_markup)
      lines = text.gsub(/\r\n?/, "\n").split("\n", -1).map {|line|
        from_markup ? line.gsub(/[[:blank:]]+/, ' ').strip : line.rstrip
      }
      normalized = lines.each_with_object([]) {|line, kept|
        next if line.empty? && (kept.empty? || kept.last.empty?)

        kept << line
      }
      normalized.pop while !normalized.empty? && normalized.last.empty?
      normalized.empty? ? '' : normalized.join("\n") + "\n"
    end

    # One line per run rather than one per item: this log shares standard
    # output with the document, and the Recipe decides which of them is wanted
    # there. See doc/PLUGINS.md section 6.7.
    def write(sections)
      document = sections.join
      counted = sections.size == 1 ? '1 item' : "#{sections.size} items"
      if @file.nil?
        @output.print(document)
        Automatic::Log.puts('info', "Publish Markdown: #{counted} to standard output")
      else
        FileUtils.mkdir_p(File.dirname(@file))
        File.open(@file, @mode, encoding: 'UTF-8') {|out| out.print(document) }
        Automatic::Log.puts('info', "Publish Markdown: #{counted} to #{@file}")
      end
    end
  end
end
