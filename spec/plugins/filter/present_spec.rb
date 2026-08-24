# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Present
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 24, 2026
# Updated::     Aug 24, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/present'

describe Automatic::Plugin::FilterPresent do
  def present(config, pipeline)
    Automatic::Plugin::FilterPresent.new(config, pipeline).run
  end

  it 'keeps only items where every configured field is present' do
    returned = present({ 'fields' => %w[title description] },
      AutomaticSpec.generate_pipeline {
        feed {
          item 'https://example.com/a', 'A', 'body A'
          item 'https://example.com/b', 'B', ''
          item 'https://example.com/c', '', 'body C'
        }
      })

    returned.should have(1).feed
    returned[0].items.should have(1).item
    returned[0].items[0].title.should == 'A'
  end

  it 'treats whitespace-only text as absent' do
    returned = present({ 'fields' => %w[description] },
      AutomaticSpec.generate_pipeline {
        feed { item 'https://example.com/a', 'A', " \n\t " }
      })

    returned.should == []
  end

  it 'accepts a single present field' do
    returned = present({ 'fields' => %w[description] },
      AutomaticSpec.generate_pipeline {
        feed {
          item 'https://example.com/a', 'A', 'body'
          item 'https://example.com/b', 'B', ''
        }
      })

    returned.should have(1).feed
    returned[0].items.should have(1).item
    returned[0].items[0].title.should == 'A'
  end

  it 'rejects a non-list fields setting' do
    lambda { Automatic::Plugin::FilterPresent.new({ 'fields' => 'description' }, []) }.
      should raise_error(ArgumentError, 'FilterPresent takes fields as a list')
  end

  it 'rejects an empty fields list' do
    lambda { Automatic::Plugin::FilterPresent.new({ 'fields' => [] }, []) }.
      should raise_error(ArgumentError, 'FilterPresent needs a non-empty fields list')
  end

  it 'rejects unknown fields' do
    lambda { Automatic::Plugin::FilterPresent.new({ 'fields' => %w[title date] }, []) }.
      should raise_error(
        ArgumentError,
        'FilterPresent cannot inspect date; the fields are title, link, description, ' \
        'author, comments, source, content_encoded'
      )
  end

  it 'rejects duplicated fields' do
    lambda { Automatic::Plugin::FilterPresent.new({ 'fields' => %w[title title] }, []) }.
      should raise_error(ArgumentError, 'FilterPresent was given title twice')
  end

  it 'rejects a missing fields setting' do
    lambda { Automatic::Plugin::FilterPresent.new({}, []) }.
      should raise_error(ArgumentError, 'FilterPresent takes fields as a list')
  end
end
