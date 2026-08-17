# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Store::Digest
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 17, 2026
# Updated::     Aug 17, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# The store plugins keep their records in SQLite through ActiveRecord. Both
# gems are the store plugins' own, declared in the Gemfile's optional :plugins
# and :store groups, so this spec runs only where the operator has installed
# them. See doc/POLICY.md section 5.
return unless AutomaticSpec.optional_dependency?('activerecord') &&
              AutomaticSpec.optional_dependency?('sqlite3')

require 'store/digest'
require 'digest'
require 'pathname'

# Items with the fields these examples are about. The pipeline generator in
# spec_helper builds an item from a positional list that has no
# content_encoded, and a digest taken over a body needs one.
module DigestSpec
  module_function

  def feed(*items)
    channel = RSS::Rss::Channel.new
    items.each { |attributes| channel.items << item(attributes) }
    rss = RSS::Rss.new([])
    rss.instance_variable_set(:@channel, channel)
    rss
  end

  def item(attributes)
    item = RSS::Rss::Channel::Item.new
    item.link  = attributes.fetch(:link, 'https://example.com/news/1')
    item.title = attributes[:title] unless attributes[:title].nil?
    item.instance_variable_set(:@description, attributes.fetch(:description, '').to_s)
    item.author = attributes[:author] unless attributes[:author].nil?
    item.content_encoded = attributes[:content_encoded] unless attributes[:content_encoded].nil?
    item
  end

  # The canonical representation the plugin hashes, written out here rather
  # than taken from the plugin, so that an example asserts the format instead
  # of agreeing with whatever the plugin currently builds.
  def digest(*pairs)
    ::Digest::SHA256.hexdigest(pairs.map { |field, value| "#{field}\0#{value}" }.join("\0"))
  end
end

describe Automatic::Plugin::StoreDigest do
  let(:db)     { 'test_digest.db' }
  let(:record) { Automatic::Plugin::DigestRecord }

  # A run of a Recipe: the plugin is built for the pipeline it is handed, and
  # the next run is the next instance, as the framework builds it.
  def run(config, *feeds)
    Automatic::Plugin::StoreDigest.new({ 'db' => db }.merge(config), feeds).run
  end

  def reset_database
    path = Pathname(AutomaticSpec.db_dir).cleanpath + db
    path.delete if path.exist?
  end

  # The file is removed and the table rebuilt, so that an example starts having
  # seen nothing and can ask the model for a count.
  before do
    reset_database
    Automatic::Plugin::StoreDigest.new('db' => db).run
  end

  describe 'what it passes on' do
    it 'passes on an item it has not seen' do
      returned = run({}, DigestSpec.feed(title: 'Ruby 4.0 released',
                                         description: 'Ruby 4.0 is now available.'))

      returned.should have(1).feed
      returned.first.items.should have(1).item
      returned.first.items.first.title.should eq 'Ruby 4.0 released'
    end

    it 'stores the digest of an item it has not seen' do
      lambda {
        run({}, DigestSpec.feed(title: 'Ruby 4.0 released',
                                description: 'Ruby 4.0 is now available.'))
      }.should change(record, :count).by(1)

      record.first.digest.should eq DigestSpec.digest(
        ['title', 'Ruby 4.0 released'],
        ['description', 'Ruby 4.0 is now available.']
      )
    end

    it 'drops the same item on the next run' do
      feed = lambda {
        DigestSpec.feed(title: 'Ruby 4.0 released', description: 'Ruby 4.0 is now available.')
      }

      run({}, feed.call).should have(1).feed
      lambda {
        run({}, feed.call).should have(0).feed
      }.should change(record, :count).by(0)
    end

    it 'passes on the first of two items of one content in one run' do
      returned = run({}, DigestSpec.feed(
        { link: 'https://example.com/a', title: 'Ruby 4.0 released',
          description: 'Ruby 4.0 is now available.' },
        { link: 'https://example.com/b', title: 'Ruby 4.0 released',
          description: 'Ruby 4.0 is now available.' }
      ))

      returned.first.items.should have(1).item
      record.count.should eq 1
    end

    it 'passes on the first of two feeds of one content in one run' do
      returned = run({},
                     DigestSpec.feed(title: 'Ruby 4.0 released',
                                     description: 'Ruby 4.0 is now available.'),
                     DigestSpec.feed(title: 'Ruby 4.0 released',
                                     description: 'Ruby 4.0 is now available.'))

      returned.should have(1).feed
      returned.first.items.should have(1).item
      record.count.should eq 1
    end

    it 'takes two links to one content as one item' do
      run({}, DigestSpec.feed(link: 'https://example.com/a', title: 'Ruby 4.0 released',
                              description: 'Ruby 4.0 is now available.'))

      returned = run({}, DigestSpec.feed(link: 'https://example.com/b',
                                         title: 'Ruby 4.0 released',
                                         description: 'Ruby 4.0 is now available.'))
      returned.should have(0).feed
    end

    # The difference from StorePermalink: the link is not what identifies an
    # item here, so one URL whose content changed is a new item.
    it 'takes one link with new content as a new item' do
      run({}, DigestSpec.feed(link: 'https://example.com/a', title: 'Ruby 4.0 released',
                              description: 'Ruby 4.0 is now available.'))

      returned = run({}, DigestSpec.feed(link: 'https://example.com/a',
                                         title: 'Ruby 4.0.1 released',
                                         description: 'Ruby 4.0.1 is now available.'))
      returned.should have(1).feed
      record.count.should eq 2
    end
  end

  describe 'fields' do
    it 'takes the digest over title and description by default' do
      run({}, DigestSpec.feed(title: 'A title', description: 'A description',
                              author: 'An author'))

      record.first.digest.should eq DigestSpec.digest(['title', 'A title'],
                                                      ['description', 'A description'])
    end

    it 'takes the digest over title alone when asked to' do
      config = { 'fields' => ['title'] }
      run(config, DigestSpec.feed(title: 'A title', description: 'One description'))

      returned = run(config, DigestSpec.feed(title: 'A title',
                                             description: 'Another description'))
      returned.should have(0).feed
      record.first.digest.should eq DigestSpec.digest(['title', 'A title'])
    end

    it 'takes the digest over description alone when asked to' do
      config = { 'fields' => ['description'] }
      run(config, DigestSpec.feed(title: 'One title', description: 'A description'))

      returned = run(config, DigestSpec.feed(title: 'Another title',
                                             description: 'A description'))
      returned.should have(0).feed
      record.first.digest.should eq DigestSpec.digest(['description', 'A description'])
    end

    it 'takes the digest over the link when asked to' do
      config = { 'fields' => ['link'] }
      run(config, DigestSpec.feed(link: 'https://example.com/a', title: 'One title'))

      run(config, DigestSpec.feed(link: 'https://example.com/a',
                                  title: 'Another title')).should have(0).feed
      run(config, DigestSpec.feed(link: 'https://example.com/b',
                                  title: 'One title')).should have(1).feed
    end

    it 'takes the digest over content_encoded when asked to' do
      config = { 'fields' => ['content_encoded'] }
      run(config, DigestSpec.feed(title: 'One title', content_encoded: '<p>A body.</p>'))

      run(config, DigestSpec.feed(title: 'Another title',
                                  content_encoded: '<p>A body.</p>')).should have(0).feed
      run(config, DigestSpec.feed(title: 'One title',
                                  content_encoded: '<p>Another body.</p>')).should have(1).feed
    end

    it 'names every field it was given in the canonical representation' do
      run({ 'fields' => %w[title link description] },
          DigestSpec.feed(link: 'https://example.com/a', title: 'A title',
                          description: 'A description'))

      record.first.digest.should eq DigestSpec.digest(['title', 'A title'],
                                                      ['link', 'https://example.com/a'],
                                                      ['description', 'A description'])
    end

    it 'takes the fields in the order the Recipe wrote them' do
      item = { title: 'A title', description: 'A description' }

      run({ 'fields' => %w[title description] }, DigestSpec.feed(item))
      forward = record.first.digest

      reset_database
      run({ 'fields' => %w[description title] }, DigestSpec.feed(item))
      record.first.digest.should_not eq forward
    end
  end

  # Two items, one run after the other: one record where the plugin read them
  # as one content, two where it read them as two.
  describe 'normalization' do
    def records_for(first, second)
      run({}, DigestSpec.feed(first))
      run({}, DigestSpec.feed(second))
      record.count
    end

    it 'reads a run of spaces as one space' do
      records_for({ title: 'Ruby 4.0  released', description: 'Out now.' },
                  { title: 'Ruby 4.0 released', description: 'Out now.' }).should eq 1
    end

    it 'reads a newline as a space' do
      records_for({ title: "Ruby 4.0\nreleased", description: 'Out now.' },
                  { title: 'Ruby 4.0 released', description: 'Out now.' }).should eq 1
    end

    it 'reads a tab as a space' do
      records_for({ title: "Ruby 4.0\treleased", description: 'Out now.' },
                  { title: 'Ruby 4.0 released', description: 'Out now.' }).should eq 1
    end

    it 'ignores whitespace around a value' do
      records_for({ title: '  Ruby 4.0 released  ', description: "Out now.\n" },
                  { title: 'Ruby 4.0 released', description: 'Out now.' }).should eq 1
    end

    # The same word composed and decomposed: U+00E9, and e followed by the
    # combining acute accent U+0301.
    it 'reads the two Unicode compositions of one string as one string' do
      records_for({ title: "Café opens", description: 'Out now.' },
                  { title: "Café opens", description: 'Out now.' }).should eq 1
    end

    it 'reads a difference in case as different content' do
      records_for({ title: 'Ruby 4.0 Released', description: 'Out now.' },
                  { title: 'Ruby 4.0 released', description: 'Out now.' }).should eq 2
    end

    it 'reads a difference in punctuation as different content' do
      records_for({ title: 'Ruby 4.0 released!', description: 'Out now.' },
                  { title: 'Ruby 4.0 released', description: 'Out now.' }).should eq 2
    end
  end

  describe 'an item with nothing to hash' do
    let(:config) { { 'fields' => ['description'] } }

    it 'stores no digest when every field it was given is empty' do
      lambda {
        run(config, DigestSpec.feed(title: 'A title', description: '   '))
      }.should change(record, :count).by(0)
    end

    it 'passes the item on rather than losing it' do
      returned = run(config, DigestSpec.feed(title: 'A title', description: ''))

      returned.should have(1).feed
      returned.first.items.should have(1).item
    end

    it 'takes a digest while any field it was given has content' do
      lambda {
        run({}, DigestSpec.feed(title: 'Ruby 4.0 released', description: ''))
      }.should change(record, :count).by(1)

      record.first.digest.should eq DigestSpec.digest(['title', 'Ruby 4.0 released'],
                                                      ['description', ''])
    end
  end

  describe 'a Recipe it cannot carry out' do
    def error_for(config)
      lambda {
        run(config, DigestSpec.feed(title: 'A title', description: 'A description'))
      }
    end

    it 'refuses an empty fields list' do
      error_for('fields' => []).should raise_error(ArgumentError)
    end

    it 'refuses a field it has no value for' do
      error_for('fields' => %w[title foobar]).should raise_error(ArgumentError, /foobar/)
    end

    it 'refuses fields that are not a list' do
      error_for('fields' => 'title').should raise_error(ArgumentError)
    end

    it 'refuses a field named twice' do
      error_for('fields' => %w[title title]).should raise_error(ArgumentError, /title/)
    end

    it 'refuses a Recipe with no db' do
      lambda {
        Automatic::Plugin::StoreDigest.new({}, []).run
      }.should raise_error(ArgumentError)
    end

    it 'refuses a db that is an empty name' do
      lambda {
        Automatic::Plugin::StoreDigest.new({ 'db' => '' }, []).run
      }.should raise_error(ArgumentError)
    end
  end

  describe 'the pipeline it returns' do
    it 'skips a nil feed' do
      returned = run({}, nil, DigestSpec.feed(title: 'A title', description: 'A description'))

      returned.should have(1).feed
      returned.first.items.should have(1).item
    end

    it 'returns no feed where every item of one has been seen' do
      feed = lambda { DigestSpec.feed(title: 'A title', description: 'A description') }

      run({}, feed.call).should have(1).feed
      run({}, feed.call).should have(0).feed
    end

    it 'returns a feed of the new items where a feed holds both' do
      run({}, DigestSpec.feed(title: 'A title', description: 'A description'))

      returned = run({}, DigestSpec.feed(
        { link: 'https://example.com/a', title: 'A title', description: 'A description' },
        { link: 'https://example.com/b', title: 'A new title',
          description: 'A new description' }
      ))

      returned.should have(1).feed
      returned.first.items.should have(1).item
      returned.first.items.first.title.should eq 'A new title'
    end

    it 'judges each of several feeds on its own' do
      returned = run({},
                     DigestSpec.feed(title: 'One title', description: 'One description'),
                     DigestSpec.feed(title: 'Another title',
                                     description: 'Another description'))

      returned.should have(2).feeds
      record.count.should eq 2
    end

    it 'returns the shape every plugin returns' do
      returned = run({}, DigestSpec.feed(title: 'A title', description: 'A description'))

      returned.should be_an(Array)
      returned.each { |feed| feed.should respond_to(:items) }
    end
  end

  describe 'a database that fails' do
    let(:feed) { DigestSpec.feed(title: 'A title', description: 'A description') }

    # The point of this plugin is that what it passed on is recorded. An item
    # passed on after a failed write would be published again next run, so the
    # failure ends the run instead.
    it 'does not swallow a failed write' do
      record.stub(:create!) { raise ActiveRecord::StatementInvalid, 'no such table' }

      lambda { run({}, feed) }.should raise_error(ActiveRecord::StatementInvalid)
    end

    # Two runs of one Recipe overlapping: both read the digest as absent, and
    # the unique index is what stops the second from storing it twice. The
    # stubbed read is how one process is made to see what the other had not
    # committed when it looked.
    it 'reads a rejected duplicate write as an item it has seen' do
      run({}, feed)
      record.stub(:exists?).and_return(false)

      lambda {
        run({}, DigestSpec.feed(title: 'A title', description: 'A description')).
          should have(0).feed
      }.should change(record, :count).by(0)
    end

    it 'does not swallow a failed read' do
      record.stub(:exists?) { raise ActiveRecord::StatementInvalid, 'database is locked' }

      lambda { run({}, feed) }.should raise_error(ActiveRecord::StatementInvalid)
    end
  end

  it 'stores a SHA-256 digest, which is 64 hexadecimal characters' do
    run({}, DigestSpec.feed(title: 'A title', description: 'A description'))

    record.first.digest.should match(/\A[0-9a-f]{64}\z/)
  end
end
