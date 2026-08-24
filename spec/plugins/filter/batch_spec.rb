# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Batch
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 24, 2026
# Updated::     Aug 24, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/batch'

describe Automatic::Plugin::FilterBatch do
  def batch(config, pipeline)
    Automatic::Plugin::FilterBatch.new(config, pipeline).run
  end

  let(:pipeline) {
    AutomaticSpec.generate_pipeline {
      feed {
        item 'https://example.com/a', 'A', 'the body of A'
        item 'https://example.com/b', 'B', 'the body of B'
        item 'https://example.com/c', 'C', 'the body of C'
      }
      feed {
        item 'https://example.com/d', 'D', 'the body of D'
        item 'https://example.com/e', 'E', 'the body of E'
        item 'https://example.com/f', 'F', 'the body of F'
        item 'https://example.com/g', 'G', 'the body of G'
      }
    }
  }

  describe 'batching across feed boundaries' do
    let(:returned) { batch({ 'batch_items' => 3 }, pipeline) }
    let(:descriptions) { returned[0].items.map(&:description) }

    it 'puts every batch into one output feed' do
      returned.should have(1).feed
      returned[0].items.should have(3).items
    end

    it 'titles each batch item in order' do
      returned[0].items.map(&:title).should == ['Batch 1', 'Batch 2', 'Batch 3']
    end

    it 'sets no link on a batch item' do
      returned[0].items.map(&:link).should == [nil, nil, nil]
    end

    it 'groups A, B and C as ARTICLE 1 through 3 in the first batch' do
      %w[A B C].each { |title| descriptions[0].should include("Title: #{title}") }
      descriptions[0].should include('ARTICLE 1')
      descriptions[0].should include('ARTICLE 2')
      descriptions[0].should include('ARTICLE 3')
    end

    it 'groups D, E and F as ARTICLE 1 through 3 in the second batch' do
      %w[D E F].each { |title| descriptions[1].should include("Title: #{title}") }
      descriptions[1].should include('ARTICLE 1')
      descriptions[1].should include('ARTICLE 2')
      descriptions[1].should include('ARTICLE 3')
    end

    it 'puts G alone as ARTICLE 1 in the third batch' do
      descriptions[2].should include('Title: G')
      descriptions[2].should include('ARTICLE 1')
    end

    it 'carries the original title, URL and description into each ARTICLE' do
      descriptions[0].should include('Title: A')
      descriptions[0].should include('URL: https://example.com/a')
      descriptions[0].should include('the body of A')
    end

    it 'restarts ARTICLE numbering at the second batch rather than continuing it' do
      descriptions[1].index('ARTICLE 1').should < descriptions[1].index('ARTICLE 2')
      descriptions[1].should_not include('ARTICLE 4')
    end
  end

  it 'accepts batch_items as a numeric string' do
    returned = batch({ 'batch_items' => '2' }, pipeline)

    returned.should have(1).feed
    returned[0].items.should have(4).items
  end

  it 'returns an empty pipeline for empty input' do
    batch({ 'batch_items' => 2 }, []).should == []
  end

  it 'rejects invalid batch_items' do
    [nil, 0, -1, '', 'abc', '1.5'].each do |value|
      lambda { Automatic::Plugin::FilterBatch.new({ 'batch_items' => value }, []) }.
        should raise_error(ArgumentError, 'FilterBatch needs batch_items to be a positive integer')
    end
  end
end
