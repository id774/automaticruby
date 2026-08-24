# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Limit
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 24, 2026
# Updated::     Aug 24, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/limit'

describe Automatic::Plugin::FilterLimit do
  def limit(config, pipeline)
    Automatic::Plugin::FilterLimit.new(config, pipeline).run
  end

  # Automatic::FeedMaker.create_pipeline sorts each feed it builds by date,
  # newest first; explicit, descending dates are what keep the output feeds'
  # own item order predictable enough to assert on here.
  let(:pipeline) {
    AutomaticSpec.generate_pipeline {
      feed {
        item 'https://example.com/a', 'A', '', 'Mon, 07 Mar 2011 15:54:12 +0900'
        item 'https://example.com/b', 'B', '', 'Mon, 07 Mar 2011 15:54:11 +0900'
      }
      feed {
        item 'https://example.com/c', 'C', '', 'Mon, 07 Mar 2011 15:54:10 +0900'
        item 'https://example.com/d', 'D', '', 'Mon, 07 Mar 2011 15:54:09 +0900'
      }
    }
  }

  it 'limits the whole pipeline instead of each feed' do
    returned = limit({ 'max_items' => 3 }, pipeline)

    returned.should have(2).feeds
    returned[0].items.should have(2).items
    returned[1].items.should have(1).item

    links = returned.flat_map { |feeds| feeds.items.map(&:link) }
    links.should == %w[https://example.com/a https://example.com/b https://example.com/c]
    links.should_not include('https://example.com/d')
  end

  it 'keeps every item when max_items exceeds the pipeline size' do
    returned = limit({ 'max_items' => 10 }, pipeline)

    returned.sum { |feeds| feeds.items.size }.should == 4
  end

  it 'accepts max_items as a numeric string' do
    returned = limit({ 'max_items' => '2' }, pipeline)

    returned.sum { |feeds| feeds.items.size }.should == 2
  end

  it 'returns an empty pipeline for empty input' do
    limit({ 'max_items' => 2 }, []).should == []
  end

  it 'rejects invalid max_items' do
    [nil, 0, -1, '', 'abc', '1.5'].each do |value|
      lambda { Automatic::Plugin::FilterLimit.new({ 'max_items' => value }, []) }.
        should raise_error(ArgumentError, 'FilterLimit needs max_items to be a positive integer')
    end
  end
end
