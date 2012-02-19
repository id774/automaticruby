#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rexml/document'
require 'rexml/parsers/pullparser'

module OPML
  def self::unnormalize(text)
    text.gsub(/&(\w+);/) {
      x = $1
      case x
      when 'lt'
        '<'
      when 'gt'
        '>'
      when 'quot'
        '"'
      when 'amp'
        '&'
      when 'apos'
        "'"
      when /^\#(\d+)$/
        [$1.to_i].pack("U")
      when /^\#x([0-9a-f]+)$/i
        [$1.hex].pack("U")
      else
        raise "unnormalize error '#{x}'"
      end
    }
  end

  module DOM
    class Element
      include Enumerable
      
      def initialize
        @attr = {}
        @parent = nil
        @children = []
      end
      attr_accessor :parent
      attr_reader :attr, :children

      def each
        yield self
        @children.each {|c|
          c.each {|x|
            yield x
          }
        }
      end

      def <<(elem)
        elem.parent = self if elem.respond_to? :parent=
        @children << elem
        self
      end

      def [](n)
        if n.is_a? String
          @attr[n]
        else
          @children[n]
        end
      end

      def []=(k,v)
        if k.is_a? String
          @attr[k] = v
        else
          @children[k] = v
        end
      end

      def text
        @attr['text']
      end

      def type
        @attr['type']
      end

      def is_comment?
        @attr['isComment']=='true'
      end
      
      def is_breaakpoint?
        @attr['isBreakpoint']=='true'
      end
    end # Element

    class OPML < Element
      def head
        @children.find {|x| x.is_a? Head }
      end
      
      def body
        @children.find {|x| x.is_a? Body }
      end
    end

    class Head < Element
    end

    class Body < Element
      def outline
        @children.find {|x| x.is_a? Outline }
      end
    end

    class Outline < Element
      def method_missing(name,*arg,&block)
        name = name.to_s
        case name
        when /^[a-z][0-9a-zA-Z_]*$/
          key = name.gsub(/_([a-z])/) {|x| ".#{$1.upcase}" }
          @attr[key]
        else
          raise NoMethodError
        end
      end
    end
  end # Model

  class Parser
    def initialize(port)
      @p = REXML::Parsers::PullParser.new(port)
      @opml = nil
    end

    def parse_tree
      root = cur = nil
      while event=@p.pull
        case event.event_type
        when :xmldecl
          encoding = event[1]
        when :start_element
          case event[0]
          when "opml"
            root = cur = DOM::OPML.new
          when "head"
            e = DOM::Head.new
            cur << e
            cur = e
          when "body"
            e = DOM::Body.new
            cur << e
            cur = e
          when "outline"
            e = DOM::Outline.new
            cur << e
            cur = e
          else
            cur['.' + event[0]] = read_text
          end
          event[1].each {|k,v|
            cur[k] = OPML::unnormalize(v)
          }
        when :end_element
          cur = cur.parent
        when :text
        when :cdata
        when :start_doctype
        when :end_doctype,:comment
        when :end_document
          break
        else
          p event.event_type
          p event
          raise "unknown event"
        end
      end # while
      root
    end # parse_tree

    def each_outline
      root = cur = nil
      while event=@p.pull
        case event.event_type
        when :xmldecl
          encoding = event[1]
        when :start_element
          case event[0]
          when "opml"
            root = cur = DOM::OPML.new
          when "head"
            e = DOM::Head.new
            cur << e
            cur = e
          when "body"
            e = DOM::Body.new
            cur << e
            cur = e
          when "outline"
            e = DOM::Outline.new
            # cur << e
            cur = e
          else
            cur['_' + event[0]] = read_text
          end
          event[1].each {|k,v|
            cur[k] = OPML::unnormalize(v)
          }
          if event[0]=="outline"
            yield root, cur
          end
        when :end_element
          cur = cur.parent if cur.kind_of? DOM::Element
        when :text
        when :cdata
        when :start_doctype
        when :end_doctype,:comment
        when :end_document
          break
        else
          p event.event_type
          p event
          raise "unknown event"
        end
      end # while
    end # each_outline

    def read_text
      text = ""
      while event = @p.pull
        case event.event_type
        when :end_element
          break
        when :text
          text << OPML::unnormalize(event[0])
        when :cdata
          text << event[0]
        else
          raise
        end
      end
      text
    end
  end # Parser
end # OPML

if __FILE__ == $0
  parser = OPML::Parser.new(File.read('opml.xml'))
  parser.each_outline {|opml, o|
    puts "#{o.xmlUrl}"
  }
end
