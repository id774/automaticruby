# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Join
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 17, 2026
# Updated::     Aug 17, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/join'

describe Automatic::Plugin::FilterJoin do
  def join(config, pipeline)
    Automatic::Plugin::FilterJoin.new(config, pipeline).run
  end

  describe 'what it returns' do
    it 'joins one feed of one item into one feed of one item' do
      returned = join({}, AutomaticSpec.generate_pipeline {
        feed { item 'https://example.com/a', 'A', 'the body of A' }
      })

      returned.should have(1).feed
      returned[0].items.should have(1).item
      returned[0].items[0].description.should include('the body of A')
    end

    it 'joins several items of one feed into one item' do
      returned = join({}, AutomaticSpec.generate_pipeline {
        feed {
          item 'https://example.com/a', 'A', 'the body of A'
          item 'https://example.com/b', 'B', 'the body of B'
          item 'https://example.com/c', 'C', 'the body of C'
        }
      })

      returned.should have(1).feed
      returned[0].items.should have(1).item
      description = returned[0].items[0].description
      %w[A B C].each { |title| description.should include("Title: #{title}") }
    end

    it 'joins the whole pipeline, not each feed' do
      returned = join({}, AutomaticSpec.generate_pipeline {
        feed { item 'https://example.com/a', 'A', 'the body of A' }
        feed {
          item 'https://example.com/b', 'B', 'the body of B'
          item 'https://example.com/c', 'C', 'the body of C'
        }
      })

      returned.should have(1).feed
      returned[0].items.should have(1).item
      returned[0].items[0].description.should include('the body of C')
    end

    it 'ignores a feed that is nil' do
      pipeline = AutomaticSpec.generate_pipeline {
        feed { item 'https://example.com/a', 'A', 'the body of A' }
      }
      returned = join({}, [nil] + pipeline + [nil])

      returned.should have(1).feed
      returned[0].items.should have(1).item
      returned[0].items[0].description.should include('the body of A')
    end
  end

  describe 'when there is nothing to join' do
    it 'returns an empty pipeline for an empty one' do
      join({}, []).should == []
    end

    it 'returns an empty pipeline when every feed is nil' do
      join({}, [nil, nil]).should == []
    end

    it 'makes no item out of feeds that carry none' do
      join({}, AutomaticSpec.generate_pipeline { feed {} }).should == []
    end
  end

  describe 'the joined description' do
    subject {
      join({}, AutomaticSpec.generate_pipeline {
        feed {
          item 'https://example.com/a', 'Ruby 4.1 released', 'the body of A'
          item 'https://example.com/b', 'PostgreSQL 19 released', 'the body of B'
        }
      })[0].items[0].description
    }

    it 'numbers each item so that what reads it can tell them apart' do
      subject.should include('ARTICLE 1')
      subject.should include('ARTICLE 2')
    end

    it 'carries the title, the link and the body of each item' do
      subject.should include('Title: Ruby 4.1 released')
      subject.should include('URL: https://example.com/a')
      subject.should include('the body of A')
    end

    it 'keeps the items in the order they arrived' do
      subject.index('Ruby 4.1 released').should < subject.index('PostgreSQL 19 released')
    end

    it 'adds no prompt of its own' do
      subject.should_not match(/summar|要約/i)
    end

    it 'treats a missing title, link or description as empty' do
      description = join({}, AutomaticSpec.generate_pipeline {
        feed { item nil, '', '' }
        feed { item 'https://example.com/b', 'B', 'the body of B' }
      })[0].items[0].description

      description.should include("ARTICLE 1\nTitle: \nURL: \n")
      description.should include('the body of B')
    end
  end

  describe 'the joined item' do
    let(:joined) {
      join(config, AutomaticSpec.generate_pipeline {
        feed { item 'https://example.com/a', 'A', 'the body of A' }
      })[0].items[0]
    }

    context 'with no title configured' do
      let(:config) { {} }

      it 'takes the default title' do
        joined.title.should == Automatic::Plugin::FilterJoin::DEFAULT_TITLE
      end

      # There is no page this item points at, and the first article's URL would
      # name a source for text that is not only from it.
      it 'invents no permalink of its own' do
        joined.link.should be_nil
      end
    end

    context 'with a title configured' do
      let(:config) { { 'title' => 'Daily Digest' } }

      it 'takes the title the Recipe gives it' do
        joined.title.should == 'Daily Digest'
      end
    end
  end
end
