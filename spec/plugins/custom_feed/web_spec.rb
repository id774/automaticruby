# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::CustomFeed::Web
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 17, 2026
# Updated::     Aug 17, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# CustomFeedWeb reads HTML with nokogiri, which the Gemfile declares in its
# optional :plugins group. The default suite and CI do not install it, so this
# spec runs only where the operator has. See doc/POLICY.md section 5.
return unless AutomaticSpec.optional_dependency?('nokogiri')

require 'custom_feed/web'
require 'stringio'

# Nothing here reaches a network: Automatic::Http.open yields the page the
# example wrote, and everything this plugin decides -- which links are
# articles, what they resolve to, what their titles are -- it decides between
# that page and the feed it returns, which is what a local double can hold
# still.
module WebSpec
  module_function

  # What open-uri hands a caller: the bytes of the page, tagged with the
  # encoding open-uri settled on. The plugin gives the stream to the parser
  # rather than a decoded string, so the double is a stream.
  def response(body, content_type = 'text/html; charset=UTF-8')
    io = StringIO.new(body.dup.force_encoding('UTF-8'))
    io.define_singleton_method(:meta) { { 'content-type' => content_type } }
    io
  end

  def page(body, head = '<title>Example News</title>')
    "<html><head>#{head}</head><body>#{body}</body></html>"
  end
end

describe Automatic::Plugin::CustomFeedWeb do
  let(:source)   { 'https://example.com/news/' }
  let(:body)     { '<a href="/articles/42">First article</a>' }
  let(:head)     { '<title>Example News</title>' }
  let(:pages)    { { source => WebSpec.page(body, head) } }
  let(:incoming) { [] }

  before do
    Automatic::Http.stub(:open) { |url, &block|
      html = pages[url.to_s]
      raise "the spec did not expect a request for #{url}" if html.nil?

      block.call(WebSpec.response(html))
    }
  end

  # One site, whose settings the example adds to, and the pipeline it returns.
  def run(site = {}, config = {}, pipeline = incoming)
    described_class.new(
      { 'sites' => [{ 'url' => source }.merge(site)] }.merge(config), pipeline
    ).run
  end

  def items(site = {}, config = {})
    run(site, config)[0].items
  end

  def links(site = {}, config = {})
    items(site, config).map(&:link)
  end

  describe 'the generic mode' do
    let(:body) {
      '<p>intro</p>' \
        '<a href="/articles/42">First article</a>' \
        '<a href="/articles/43">Second article</a>'
    }

    it 'makes an item of every a[href]' do
      run.should have(1).feed
      items.should have(2).items
    end

    it 'takes the anchor text as the title' do
      items.map(&:title).should == ['First article', 'Second article']
    end

    it 'keeps the order the page lists them in' do
      links.should == ['https://example.com/articles/42',
                       'https://example.com/articles/43']
    end
  end

  describe 'a candidate URL' do
    it 'resolves a relative URL against the page' do
      links.should == ['https://example.com/articles/42']
    end

    context 'written with ../' do
      let(:body) { '<a href="../archive/7">Older</a>' }

      it 'resolves it' do
        links.should == ['https://example.com/archive/7']
      end
    end

    context 'written scheme-relative' do
      let(:body) { '<a href="//example.com/articles/42">Same host</a>' }

      it 'takes the scheme from the page' do
        links.should == ['https://example.com/articles/42']
      end
    end

    context 'carrying a fragment' do
      let(:body) { '<a href="/articles/42#comments">With an anchor</a>' }

      it 'drops the fragment' do
        links.should == ['https://example.com/articles/42']
      end
    end

    context 'carrying a query string' do
      let(:body) { '<a href="/article?id=42&amp;page=2">Query</a>' }

      it 'keeps the query string' do
        links.should == ['https://example.com/article?id=42&page=2']
      end
    end

    context 'that is not HTTP or HTTPS' do
      let(:body) {
        '<a href="mailto:editor@example.com">Mail</a>' \
          '<a href="javascript:void(0)">Menu</a>' \
          '<a href="ftp://example.com/pub">Archive</a>' \
          '<a href="/articles/42">Article</a>'
      }

      it 'is dropped' do
        links.should == ['https://example.com/articles/42']
      end
    end

    context 'that is the page itself' do
      let(:body) {
        '<a href="/news/">This page</a>' \
          '<a href="https://example.com/news/#top">This page again</a>' \
          '<a href="/articles/42">Article</a>'
      }

      it 'is dropped' do
        links.should == ['https://example.com/articles/42']
      end
    end

    context 'appearing twice' do
      let(:body) {
        '<a href="/articles/42">First</a>' \
          '<a href="https://example.com/articles/42">First again</a>' \
          '<a href="/articles/42#comments">First, with an anchor</a>'
      }

      it 'becomes one item' do
        links.should == ['https://example.com/articles/42']
      end
    end
  end

  describe 'a title' do
    let(:body) { "<a href=\"/articles/42\">  Ruby\n   4.0\t released  </a>" }

    it 'has its whitespace normalized' do
      items.map(&:title).should == ['Ruby 4.0 released']
    end

    context 'that is empty' do
      let(:body) {
        '<a href="/articles/42"><img src="/thumb.png"></a>' \
          '<a href="/articles/43">Second article</a>'
      }

      it 'costs the candidate its place' do
        links.should == ['https://example.com/articles/43']
      end
    end
  end

  describe 'same_host' do
    let(:body) {
      '<a href="/articles/42">Ours</a>' \
        '<a href="https://blog.example.com/x">A subdomain</a>' \
        '<a href="https://example.org/y">Another site</a>'
    }

    it 'drops another host by default, subdomains included' do
      links.should == ['https://example.com/articles/42']
    end

    it 'keeps another host when it is false' do
      links('same_host' => false).should == ['https://example.com/articles/42',
                                             'https://blog.example.com/x',
                                             'https://example.org/y']
    end
  end

  describe 'include and exclude' do
    let(:body) {
      '<a href="/news/42">An article</a>' \
        '<a href="/news/category/ruby">A category</a>' \
        '<a href="/about">Not news</a>'
    }

    it 'keeps only what include matches' do
      links('include' => ['^https://example\.com/news/']).
        should == ['https://example.com/news/42',
                   'https://example.com/news/category/ruby']
    end

    it 'drops what exclude matches' do
      links('exclude' => ['/category/']).should == ['https://example.com/news/42',
                                                    'https://example.com/about']
    end

    it 'applies exclude to what include kept' do
      links('include' => ['^https://example\.com/news/'],
            'exclude' => ['/category/']).should == ['https://example.com/news/42']
    end

    it 'keeps everything when neither is given' do
      links.should have(3).links
    end
  end

  describe 'fetch_items' do
    let(:body) {
      (1..120).map { |number| "<a href=\"/articles/#{number}\">Article #{number}</a>" }.join
    }

    it 'limits the feed to the first N the page lists' do
      links('fetch_items' => 3).should == ['https://example.com/articles/1',
                                           'https://example.com/articles/2',
                                           'https://example.com/articles/3']
    end

    it 'defaults to 100' do
      items.should have(100).items
    end

    it 'takes 0 as the default' do
      items('fetch_items' => 0).should have(100).items
    end

    it 'takes a negative value as the default' do
      items('fetch_items' => -5).should have(100).items
    end
  end

  describe 'link_selector' do
    let(:body) {
      '<nav><a href="/about">About</a></nav>' \
        '<main><h2><a href="/articles/42">An article</a></h2>' \
        '<a href="/articles/43">A bare link</a></main>'
    }

    it 'takes the anchors it names and no others' do
      links('link_selector' => 'main h2 a').should == ['https://example.com/articles/42']
    end
  end

  describe 'item_selector' do
    let(:body) {
      '<nav><a href="/about">About</a></nav>' \
        '<article>' \
        '<h2><a href="/articles/42">First article</a></h2>' \
        '<p class="summary">What it is about.</p>' \
        '<time datetime="2026-08-01T09:15:22+09:00">1 August</time>' \
        '<a href="/articles/42/comments">Comments</a>' \
        '</article>' \
        '<article>' \
        '<h2><a href="/articles/43">Second article</a></h2>' \
        '<p class="summary">Something else.</p>' \
        '<time>30 July 2026</time>' \
        '</article>'
    }
    let(:item_site) {
      { 'item_selector' => 'article', 'link_selector' => 'h2 a',
        'title_selector' => 'h2', 'description_selector' => '.summary',
        'date_selector' => 'time' }
    }

    it 'makes one item per article node' do
      items(item_site).should have(2).items
    end

    it 'evaluates link_selector inside the article' do
      links(item_site).should == ['https://example.com/articles/42',
                                  'https://example.com/articles/43']
    end

    it 'takes the first a[href] in the article when link_selector is absent' do
      links('item_selector' => 'article').should == ['https://example.com/articles/42',
                                                     'https://example.com/articles/43']
    end

    it 'takes the title from title_selector' do
      items(item_site).map(&:title).should == ['First article', 'Second article']
    end

    it 'takes the title from the link when title_selector is absent' do
      items('item_selector' => 'article', 'link_selector' => 'h2 a').
        map(&:title).should == ['First article', 'Second article']
    end

    it 'takes the description from description_selector' do
      items(item_site).map(&:description).should == ['What it is about.', 'Something else.']
    end

    it 'leaves the description empty when description_selector is absent' do
      items('item_selector' => 'article').map(&:description).should == ['', '']
    end

    describe 'a date' do
      it 'is taken from the datetime attribute of a time element' do
        items(item_site)[0].date.should == Time.parse('2026-08-01T09:15:22+09:00')
      end

      it 'is parsed from the node text where there is no datetime attribute' do
        items(item_site)[1].date.should == Time.parse('30 July 2026')
      end

      it 'is absent when date_selector is not given' do
        items('item_selector' => 'article')[0].date.should be_nil
      end

      context 'that cannot be read' do
        let(:body) {
          '<article><h2><a href="/articles/42">An article</a></h2>' \
            '<time>the other day</time></article>'
        }

        it 'costs the item its date and not its place' do
          feed = items('item_selector' => 'article', 'date_selector' => 'time')
          feed.should have(1).item
          feed[0].date.should be_nil
        end
      end
    end
  end

  describe 'the channel' do
    it 'takes its title from name' do
      run('name' => 'Example News')[0].channel.title.should == 'Example News'
    end

    it 'takes the page title where name is absent' do
      run[0].channel.title.should == 'Example News'
    end

    context 'on a page with no title element' do
      let(:head) { '' }

      it 'takes the host' do
        run[0].channel.title.should == 'example.com'
      end
    end

    it 'links to the page it was built from' do
      run[0].channel.link.should == source
    end
  end

  describe 'a site that cannot be fetched' do
    let(:other)  { 'https://example.org/news/' }
    let(:pages)  { { other => WebSpec.page('<a href="/articles/7">Theirs</a>') } }
    let(:plugin) {
      described_class.new(
        'retry' => 0, 'sites' => [{ 'url' => source }, { 'url' => other }]
      )
    }

    before do
      Automatic::Http.stub(:open) { |url, &block|
        raise Errno::ECONNREFUSED if url.to_s == source

        block.call(WebSpec.response(pages[url.to_s]))
      }
    end

    it 'is skipped, and the sites after it are still fetched' do
      feeds = plugin.run
      feeds.should have(1).feed
      feeds[0].items[0].link.should == 'https://example.org/articles/7'
    end

    it 'is attempted once more per retry' do
      Automatic::Http.should_receive(:open).exactly(3).times.and_raise(Errno::ECONNREFUSED)
      described_class.new('retry' => 2, 'interval' => 0,
                          'sites' => [{ 'url' => source }]).run.should be_empty
    end
  end

  # A Recipe this plugin cannot carry out will not be carried out by a second
  # attempt either. It is refused before anything is fetched.
  describe 'a settings error' do
    it 'is raised for an invalid include pattern, without fetching' do
      Automatic::Http.should_not_receive(:open)
      lambda { run('include' => ['[']) }.should raise_error(ArgumentError)
    end

    it 'is raised for an invalid exclude pattern, without fetching' do
      Automatic::Http.should_not_receive(:open)
      lambda { run('exclude' => ['(']) }.should raise_error(ArgumentError)
    end

    it 'is raised for a site with no url, without fetching' do
      Automatic::Http.should_not_receive(:open)
      lambda { described_class.new('sites' => [{ 'name' => 'No URL' }]).run }.
        should raise_error(ArgumentError)
    end

    it 'is raised for a url this framework does not fetch' do
      Automatic::Http.should_not_receive(:open)
      lambda { described_class.new('sites' => [{ 'url' => 'ftp://example.com/' }]).run }.
        should raise_error(ArgumentError)
    end

    it 'is raised for the sites shorthand, which is not accepted' do
      Automatic::Http.should_not_receive(:open)
      lambda { described_class.new('sites' => ['https://example.com/news/']).run }.
        should raise_error(ArgumentError, /mapping/)
    end

    it 'is raised where an article unit cannot be decided' do
      Automatic::Http.should_not_receive(:open)
      lambda { run('title_selector' => 'h2') }.should raise_error(ArgumentError, /item_selector/)
    end

    # An invalid selector is only found by the parser, which is on the far
    # side of the request. What matters is that the request is not repeated.
    it 'is not retried when the parser rejects a selector' do
      fetched = 0
      Automatic::Http.stub(:open) { |_url, &block|
        fetched += 1
        block.call(WebSpec.response(WebSpec.page(body)))
      }
      lambda { run({ 'link_selector' => 'h2 >>' }, 'retry' => 2) }.
        should raise_error(Nokogiri::CSS::SyntaxError)
      fetched.should == 1
    end
  end

  describe 'the pipeline' do
    let(:incoming) {
      AutomaticSpec.generate_pipeline {
        feed { item 'https://example.net/earlier', 'An earlier feed' }
      }
    }

    it 'keeps what was already in it and appends the new feed' do
      feeds = run
      feeds.should have(2).feeds
      feeds[0].items[0].link.should == 'https://example.net/earlier'
      feeds[1].items[0].link.should == 'https://example.com/articles/42'
    end

    context 'when a page yields no candidate' do
      let(:body) { '<p>Nothing to link to.</p>' }

      it 'is returned unchanged' do
        run.should == incoming
      end
    end

    it 'is returned unchanged when there are no sites' do
      described_class.new({}, incoming).run.should == incoming
    end
  end

  # nokogiri is this plugin's own dependency and not the framework's: a Recipe
  # that does not name CustomFeedWeb runs without it. See doc/POLICY.md
  # section 9.1.
  describe 'its dependency on nokogiri' do
    let(:source_file) {
      File.read(File.join(APP_ROOT, 'plugins', 'custom_feed', 'web.rb'), encoding: 'UTF-8')
    }

    it 'is required through Automatic.require_optional' do
      source_file.should include(
        "Automatic.require_optional('nokogiri', needed_by: 'CustomFeedWeb')"
      )
      source_file.should_not match(/^\s*require 'nokogiri'/)
    end

    it 'is declared as an optional plugin gem rather than a runtime one' do
      AutomaticSpec::OPTIONAL_PLUGIN_GEMS.should include('nokogiri')
      File.read(File.join(APP_ROOT, 'automatic.gemspec'), encoding: 'UTF-8').
        should_not match(/add_dependency\s+'nokogiri'/)
    end
  end
end

# Excluded from the default suite, which reaches no network. The examples
# above are what says this plugin works; this one says the page it was written
# for is still a page. Run it deliberately with AUTOMATIC_NETWORK_SPECS=1.
#
# It selects by URL rather than by selector on purpose: a pattern outlives a
# redesign, and a shipped test that depends on somebody else's markup is a
# test that breaks without anything here changing.
describe Automatic::Plugin::CustomFeedWeb, 'against a real page', :network do
  subject {
    Automatic::Plugin::CustomFeedWeb.new(
      'sites' => [{ 'url' => 'https://www.ruby-lang.org/en/news/',
                    'name' => 'Ruby News',
                    'include' => ['/en/news/20'],
                    'fetch_items' => 3 }]
    )
  }

  its(:run) { should have(1).feed }

  it 'takes the release announcements the page lists' do
    feed = subject.run[0]
    feed.channel.title.should == 'Ruby News'
    feed.items.should have(3).items
    feed.items.each { |item| item.link.should include('/en/news/20') }
  end
end
