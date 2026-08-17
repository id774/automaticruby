# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Markdown
# Description:: Render the pipeline as a Markdown document, to a file or to standard output.
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 14, 2026
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishMarkdown
    require 'fileutils'

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

    # What the substitute reducer below matches, in the order it applies them.
    COMMENT_ELEMENT = /<!--.*?-->/m
    DISCARDED_ELEMENT = %r{<(script|style)\b[^>]*>.*?</\1\s*>}mi
    BREAK_ELEMENT = /<br\b[^>]*>/i
    BLOCK_ELEMENT = %r{</?(?:#{BLOCK_ELEMENTS.join('|')})\b[^>]*>}i
    TAG = /<[^>]*>/m
    ENTITY = /&(\#\d+|\#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);/

    # The character references a feed body actually tends to carry: the five of
    # XML, and the punctuation and symbols that follow prose out of a web page.
    # A reference in neither this table nor the numeric form is left as it is
    # written, which a reader can still make sense of; the full HTML set is two
    # thousand entries and a parser's business.
    ENTITIES = {
      'amp' => '&', 'lt' => '<', 'gt' => '>', 'quot' => '"', 'apos' => "'",
      'nbsp' => "\u00A0", 'copy' => '©', 'reg' => '®', 'trade' => '™',
      'hellip' => '…', 'mdash' => '—', 'ndash' => '–', 'middot' => '·',
      'bull' => '•', 'deg' => '°', 'laquo' => '«', 'raquo' => '»',
      'lsquo' => '‘', 'rsquo' => '’', 'ldquo' => '“', 'rdquo' => '”',
      'yen' => '¥', 'pound' => '£', 'euro' => '€'
    }.freeze

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
    # ends a line, a block element ends a paragraph, entities are decoded, and
    # the tags themselves are dropped.
    #
    # A parser does it where one is installed, and the substitution below does
    # it where none is. That is what keeps this plugin -- the one a Recipe ends
    # with when the result is meant to be read -- runnable on a plain `gem
    # install automatic`: nokogiri is an optional dependency, and reducing a
    # feed body to text is not a good enough reason to make everyone install a
    # native extension.
    # The two agree on what a body is reduced to; a parser is simply better at
    # markup that is malformed. See doc/PLUGINS.md section 6.7.
    def html_to_text(html)
      html_parser? ? parsed_text(html) : substituted_text(html)
    end

    # Memoized, and false rather than an exception when the gem is absent: this
    # question is asked once per body.
    def html_parser?
      return @html_parser unless @html_parser.nil?

      @html_parser =
        begin
          require 'nokogiri'
          true
        rescue LoadError
          false
        end
    end

    def substituted_text(html)
      text = html.gsub(COMMENT_ELEMENT, '')
      text = text.gsub(DISCARDED_ELEMENT, '')
      text = text.gsub(BREAK_ELEMENT, "\n")
      text = text.gsub(BLOCK_ELEMENT, "\n\n")
      unescape(text.gsub(TAG, ''))
    end

    # One pass, so that "&amp;lt;" decodes to "&lt;" and not to "<", which is
    # what a parser does with it too.
    def unescape(text)
      text.gsub(ENTITY) {|reference|
        name = Regexp.last_match(1)
        name.start_with?('#') ? character(name) || reference
                              : ENTITIES.fetch(name, reference)
      }
    end

    # A numeric character reference, or nil where it names no character: a
    # surrogate, a value past the last code point, or zero.
    def character(name)
      code = name.start_with?('#x', '#X') ? name[2..].to_i(16) : name[1..].to_i
      return nil unless code.positive?

      begin
        code.chr(Encoding::UTF_8)
      rescue RangeError
        nil
      end
    end

    def parsed_text(html)
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
