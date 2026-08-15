# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::FullFeed
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jan 24, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# FilterFullFeed reads HTML with nokogiri, which the Gemfile declares in its
# optional :plugins group. The default suite and CI do not install it, so this
# spec runs only where the operator has. See doc/POLICY.md section 5.
return unless AutomaticSpec.optional_dependency?('nokogiri')

require 'filter/full_feed'
require 'fileutils'
require 'tmpdir'
require 'json'
require 'stringio'

# The contexts below reach no network: the siteinfo is written into a
# temporary HOME, and Automatic::Http.open yields what open-uri would have
# yielded. Everything this plugin gets wrong, it gets wrong between a link and
# a description, which is exactly what a local double can hold still.
module FullFeedSpec
  module_function

  # A siteinfo file of the shape the LDRFullFeed database has, in a temporary
  # ~/.automatic/assets/siteinfo, which is where the plugin looks first.
  def write_siteinfo(home, records)
    dir = File.join(home, '.automatic', 'assets', 'siteinfo')
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, 'test.json'), JSON.dump(records))
  end

  def record(url, xpath, enc = nil)
    { 'data' => { 'type' => 'IND', 'url' => url, 'xpath' => xpath, 'enc' => enc.to_s } }
  end

  # What open-uri hands a caller: the bytes of the page, tagged with the
  # encoding open-uri settled on, which is the charset the response declared
  # or UTF-8 where it declared none. The distinction is the point of several
  # of these examples, so the double keeps it.
  def response(body, content_type)
    charset = content_type[/charset\s*=\s*([\w-]+)/i, 1]
    io = StringIO.new(body.dup.force_encoding(charset || 'UTF-8'))
    io.define_singleton_method(:meta) { { 'content-type' => content_type } }
    io
  end
end

describe Automatic::Plugin::FilterFullFeed, 'without a network' do
  let(:home) { Dir.mktmpdir('automatic-spec-home') }
  let(:link) { 'http://example.com/article' }
  let(:content_type) { 'text/html; charset=UTF-8' }
  let(:page) do
    '<html><head><meta charset="utf-8"></head>' \
      '<body><div class="entry"><p>the whole article</p></div></body></html>'
  end

  # One item, one record matching it by default. An example that wants
  # something else overrides the `let` it needs.
  let(:records) { [FullFeedSpec.record('^http://example\.com/', '//div[@class="entry"]')] }
  let(:item) { subject.instance_variable_get(:@pipeline)[0].items[0] }

  # The pipeline generator's block is instance_eval'd, so `link` has to be a
  # local here rather than the example group's method.
  subject {
    url = link
    Automatic::Plugin::FilterFullFeed.new(
      { 'siteinfo' => 'test.json' },
      AutomaticSpec.generate_pipeline {
        feed { item url, 'a title', 'the summary the feed gave' }
      })
  }

  before do
    @real_home = ENV['HOME']
    ENV['HOME'] = home
    FullFeedSpec.write_siteinfo(home, records)
    Automatic::Http.stub(:open) { |_url, &block| block.call(FullFeedSpec.response(page, content_type)) }
  end

  after do
    ENV['HOME'] = @real_home
    FileUtils.remove_entry(home)
  end

  context "when the link matches a record" do
    it "replaces the summary with the article" do
      subject.run
      item.description.should == '<div class="entry"><p>the whole article</p></div>'
    end
  end

  # The database was last updated in 2013 and nearly every record in it is
  # anchored on ^http://, while a feed today hands out https links. Matching
  # under one scheme only is the difference between this plugin working and
  # doing nothing at all.
  context "when the link is https and the record is anchored on http" do
    let(:link) { 'https://example.com/article' }

    it "still matches the record" do
      subject.run
      item.description.should == '<div class="entry"><p>the whole article</p></div>'
    end
  end

  context "when the link is http and the record is anchored on https" do
    let(:records) { [FullFeedSpec.record('^https://example\.com/', '//div[@class="entry"]')] }

    it "still matches the record" do
      subject.run
      item.description.should == '<div class="entry"><p>the whole article</p></div>'
    end
  end

  # A record whose site has been redesigned selects nothing. Assigning that
  # empty result is worse than doing nothing: the item loses the summary it
  # arrived with and the feed goes out with an empty body.
  context "when the record matches but its XPath selects nothing" do
    let(:records) { [FullFeedSpec.record('^http://example\.com/', '//div[@class="gone"]')] }

    it "keeps the summary the feed gave" do
      subject.run
      item.description.should == 'the summary the feed gave'
    end
  end

  context "when the page cannot be read" do
    before { Automatic::Http.stub(:open).and_raise(Errno::ECONNREFUSED) }

    it "keeps the summary the feed gave" do
      subject.run
      item.description.should == 'the summary the feed gave'
    end
  end

  context "when no record matches the link" do
    let(:records) { [FullFeedSpec.record('^http://elsewhere\.example/', '//div')] }

    it "keeps the summary the feed gave" do
      subject.run
      item.description.should == 'the summary the feed gave'
    end
  end

  # An empty pattern matches every link, so a record without one would put its
  # own XPath over the whole feed.
  context "with a record that has no URL pattern" do
    let(:records) do
      [FullFeedSpec.record('', '//div[@class="entry"]'),
       FullFeedSpec.record('^http://example\.com/', '//div[@class="entry"]')]
    end

    it "ignores it" do
      subject.instance_variable_get(:@siteinfo).size.should == 1
    end
  end

  context "with a record whose pattern is not a regular expression" do
    let(:records) { [FullFeedSpec.record('^http://example\.com/broken(', '//div')] }

    it "ignores it" do
      subject.instance_variable_get(:@siteinfo).should be_empty
    end
  end

  context "with a record that has no XPath" do
    let(:records) { [FullFeedSpec.record('^http://example\.com/', '')] }

    it "ignores it" do
      subject.instance_variable_get(:@siteinfo).should be_empty
    end
  end

  # Encoding. open-uri tags a page with the charset of the response, and with
  # UTF-8 when the response named none -- which is not the same as the page
  # having said so. Handing the parser that tag instead of the page is how a
  # site that declares its charset in a meta tag turns into mojibake.
  context "when the page declares its charset only in a meta tag" do
    let(:content_type) { 'text/html' }
    let(:page) do
      ('<html><head><meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">' \
       '</head><body><div class="entry">日本語の本文</div></body></html>').encode('Shift_JIS')
    end

    it "reads the page in the encoding the page names" do
      subject.run
      item.description.should == '<div class="entry">日本語の本文</div>'
      item.description.encoding.should == Encoding::UTF_8
    end
  end

  context "when the page declares no charset anywhere" do
    let(:content_type) { 'text/html' }
    let(:page) { '<html><body><div class="entry">日本語の本文</div></body></html>'.encode('EUC-JP') }
    let(:records) { [FullFeedSpec.record('^http://example\.com/', '//div[@class="entry"]', 'EUC-JP')] }

    it "falls back to the encoding the record names" do
      subject.run
      item.description.should == '<div class="entry">日本語の本文</div>'
    end
  end

  # A record's `enc` was written in 2013. A site that has moved to UTF-8 since
  # says so in the page, and the page is the more recent of the two.
  context "when the record names an encoding the page contradicts" do
    let(:records) { [FullFeedSpec.record('^http://example\.com/', '//div[@class="entry"]', 'EUC-JP')] }
    let(:page) do
      '<html><head><meta charset="utf-8"></head>' \
        '<body><div class="entry">日本語の本文</div></body></html>'
    end

    it "believes the page" do
      subject.run
      item.description.should == '<div class="entry">日本語の本文</div>'
    end
  end

  context "when the record names an encoding that does not exist" do
    let(:records) { [FullFeedSpec.record('^http://example\.com/', '//div[@class="entry"]', 'NoSuchEncoding')] }

    it "ignores it rather than failing the run" do
      subject.run
      item.description.should == '<div class="entry"><p>the whole article</p></div>'
    end
  end

  # Whatever comes out of here is put into a feed by a publish plugin, which
  # has no way to recover from a string it cannot encode. The parser returns
  # the page in whatever encoding it settled on, so the conversion happens
  # here whether or not the page turned out to be readable.
  context "when the page's bytes do not match the charset it declares" do
    let(:page) do
      '<html><body><div class="entry">日本語の本文</div></body></html>'.encode('Shift_JIS')
    end

    it "still hands on valid UTF-8" do
      subject.run
      item.description.encoding.should == Encoding::UTF_8
      item.description.valid_encoding?.should be true
    end
  end

  describe "#run" do
    it "passes the feeds on" do
      subject.run.size.should == 1
    end

    it "leaves an item with no link alone" do
      subject.instance_variable_get(:@pipeline)[0].items[0].link = nil
      lambda { subject.run }.should_not raise_error
    end
  end

  describe "the siteinfo setting" do
    it "is required" do
      lambda { Automatic::Plugin::FilterFullFeed.new({}, []) }.
        should raise_error(ArgumentError, /siteinfo/)
    end
  end
end

describe Automatic::Plugin::FilterFullFeed do
  context "It should be matched by siteinfo", :network do
    subject {
      Automatic::Plugin::FilterFullFeed.new(
        {
          'siteinfo' => "items_all.json"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://matome.naver.jp/odai/2129948007339738701/2129948085139809603", "hoge",
            "fuga",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://matome.naver.jp/odai/2129948007339738701/2129948085139809603"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "fuga"

        subject.run

        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://matome.naver.jp/odai/2129948007339738701/2129948085139809603"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should match(/このまとめを見る/)
      }
    end
  end

  context "It should be not matched by siteinfo" do
    subject {
      Automatic::Plugin::FilterFullFeed.new(
        {
          'siteinfo' => "items_all.json"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://id774.net", "aaaaaa",
            "bbbbbb",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "bbbbbb"

        subject.run

        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "bbbbbb"
      }
    end
  end

  context "It should be not matched by siteinfo with local dir" do
    subject {
      Automatic::Plugin::FilterFullFeed.new(
        {
          'siteinfo' => "items_all.json"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://id774.net", "cccc",
            "ddddd",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }})}

    describe "#run" do
      # This exercises the plugin's preference for ~/.automatic/assets over the
      # installation's own. HOME is redirected to a temporary directory for the
      # duration: the previous version of this spec deleted the real
      # ~/.automatic/assets/siteinfo, so running the suite destroyed whatever
      # siteinfo the developer had put there.
      before do
        @real_home = ENV['HOME']
        @tmp_home = Dir.mktmpdir('automatic-spec-home')
        ENV['HOME'] = @tmp_home

        dir = File.expand_path('~/.automatic/assets/siteinfo')
        FileUtils.mkdir_p(dir)
        FileUtils.cp(File.join(APP_ROOT, 'assets/siteinfo/items_all.json'), dir)
      end

      its(:run) { should have(1).feeds }

      specify {
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "ddddd"

        subject.run

        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "ddddd"
      }

      after do
        ENV['HOME'] = @real_home
        FileUtils.rm_rf(@tmp_home)
      end
    end
  end
end
