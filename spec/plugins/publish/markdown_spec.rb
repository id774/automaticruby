# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Markdown
# Author::    774 <http://id774.net>
# Created::   Aug 14, 2026
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.
#
# Reaches no network and needs no credential. The file examples write into a
# temporary directory and never touch a real ~/.automatic.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'stringio'
require 'tmpdir'
require 'publish/markdown'

describe Automatic::Plugin::PublishMarkdown do
  # Publishes to the substituted output object, as PublishConsole does, and
  # returns what was written.
  def publish(config, pipeline)
    output = StringIO.new
    plugin = Automatic::Plugin::PublishMarkdown.new(config, pipeline)
    plugin.instance_variable_set(:@output, output)
    @returned = plugin.run
    output.string
  end

  describe 'the document' do
    before do
      @pipeline = AutomaticSpec.generate_pipeline {
        feed {
          item 'https://example.com/a', 'A title', 'A description',
               'Thu, 14 Aug 2026 10:00:00 +0900', 'someone@example.com'
        }
      }
    end

    it 'writes the title as a level-2 heading' do
      publish({}, @pipeline).should include("## A title\n")
    end

    it 'writes the link as an autolink, so a URL survives grep and a renderer' do
      publish({}, @pipeline).should include("- Link: <https://example.com/a>\n")
    end

    it 'keeps the date and the author' do
      document = publish({}, @pipeline)
      document.should include("- Date: 2026-08-14 10:00:00 +0900\n")
      document.should include("- Author: someone@example.com\n")
    end

    it 'writes the description as the body' do
      publish({}, @pipeline).should include("\nA description\n")
    end

    it 'writes nothing for a field the item does not carry' do
      publish({}, @pipeline).should_not include('Comments')
    end

    it 'ends the document with a blank line, so appending stays valid Markdown' do
      publish({}, @pipeline).should end_with("\n\n")
    end

    it 'returns the pipeline it was given' do
      publish({}, @pipeline)
      @returned.should equal(@pipeline)
    end

    it 'is deterministic' do
      publish({}, @pipeline).should == publish({}, @pipeline)
    end

    it 'needs no settings' do
      publish(nil, @pipeline).should include('## A title')
    end
  end

  describe 'an item with only a link' do
    before do
      @pipeline = AutomaticSpec.generate_pipeline {
        feed { item 'https://example.com/a' }
      }
    end

    it 'heads the section with the link and writes no body' do
      publish({}, @pipeline).should ==
        "## https://example.com/a\n\n- Link: <https://example.com/a>\n\n"
    end
  end

  describe 'HTML in a body' do
    before do
      @pipeline = AutomaticSpec.generate_pipeline {
        feed {
          item 'https://example.com/a', 'A title',
               "<div>\n  <p>First &amp; second.</p>\n" \
               "  <script>alert(1)</script>\n  <p>Third<br>fourth</p>\n</div>"
        }
      }
    end

    it 'reduces the markup to text' do
      body = publish({}, @pipeline)
      body.should include("First & second.\n")
      body.should_not include('<p>')
    end

    it 'drops a script with its contents' do
      publish({}, @pipeline).should_not include('alert(1)')
    end

    it 'keeps a break as a line break and a block element as a paragraph break' do
      publish({}, @pipeline).should include("Third\nfourth\n")
      publish({}, @pipeline).should include("First & second.\n\nThird")
    end
  end

  describe 'content_encoded' do
    before do
      @pipeline = AutomaticSpec.generate_pipeline {
        feed { item 'https://example.com/a', 'A title', 'The summary' }
      }
      @pipeline[0].items[0].content_encoded = '<p>The article body</p>'
    end

    it 'is preferred over the description' do
      document = publish({}, @pipeline)
      document.should include('The article body')
      document.should_not include('The summary')
    end
  end

  describe 'several items' do
    before do
      @pipeline = AutomaticSpec.generate_pipeline {
        feed {
          item 'https://example.com/a', 'First'
          item 'https://example.com/b', 'Second'
        }
        feed {
          item 'https://example.com/c', 'Third'
        }
      }
    end

    it 'writes them in pipeline order' do
      publish({}, @pipeline).scan(/^## (.+)$/).flatten.should == %w[First Second Third]
    end

    it 'separates the sections with a blank line' do
      publish({}, @pipeline).should include("- Link: <https://example.com/a>\n\n## Second\n")
    end

    it 'skips a feed that is nil' do
      publish({}, @pipeline + [nil]).scan(/^## /).size.should == 3
    end
  end

  describe 'Unicode' do
    before do
      @pipeline = AutomaticSpec.generate_pipeline {
        feed { item 'https://example.com/a', '日本語のタイトル', '<p>本文に &amp; を含む</p>' }
      }
    end

    it 'passes text through unchanged' do
      document = publish({}, @pipeline)
      document.should include('## 日本語のタイトル')
      document.should include('本文に & を含む')
      document.encoding.should == Encoding::UTF_8
    end
  end

  describe 'an empty pipeline' do
    it 'writes nothing' do
      publish({}, []).should == ''
    end

    it 'still returns the pipeline' do
      publish({}, [])
      @returned.should == []
    end
  end

  describe 'a file destination' do
    before do
      @pipeline = AutomaticSpec.generate_pipeline {
        feed { item 'https://example.com/a', '日本語のタイトル' }
      }
    end

    around do |example|
      Dir.mktmpdir {|dir|
        @dir = dir
        example.run
      }
    end

    it 'writes the document there, creating a missing parent directory' do
      path = File.join(@dir, 'nested', 'feeds.md')
      Automatic::Plugin::PublishMarkdown.new({ 'file' => path }, @pipeline).run
      File.read(path, encoding: 'UTF-8').should == "## 日本語のタイトル\n\n- Link: <https://example.com/a>\n\n"
    end

    it 'appends by default' do
      path = File.join(@dir, 'feeds.md')
      2.times { Automatic::Plugin::PublishMarkdown.new({ 'file' => path }, @pipeline).run }
      File.read(path, encoding: 'UTF-8').scan(/^## /).size.should == 2
    end

    it 'replaces the file when told to overwrite' do
      path = File.join(@dir, 'feeds.md')
      Automatic::Plugin::PublishMarkdown.new({ 'file' => path }, @pipeline).run
      Automatic::Plugin::PublishMarkdown.new(
        { 'file' => path, 'mode' => 'overwrite' }, @pipeline).run
      File.read(path, encoding: 'UTF-8').scan(/^## /).size.should == 1
    end

    it 'creates no file for an empty pipeline' do
      path = File.join(@dir, 'feeds.md')
      Automatic::Plugin::PublishMarkdown.new({ 'file' => path }, []).run
      File.exist?(path).should == false
    end

    it 'returns the pipeline it was given' do
      path = File.join(@dir, 'feeds.md')
      plugin = Automatic::Plugin::PublishMarkdown.new({ 'file' => path }, @pipeline)
      plugin.run.should equal(@pipeline)
    end
  end
end
