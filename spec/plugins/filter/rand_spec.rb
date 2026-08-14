# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Rand
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     May  6, 2013
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/rand'

LINKS = %w[http://aaa.png http://bbb.png http://ccc.png http://ddd.png].freeze

def rand_plugin
  Automatic::Plugin::FilterRand.new(
    {},
    AutomaticSpec.generate_pipeline {
      feed {
        LINKS.each { |link| item link }
      }
    }
  )
end

describe Automatic::Plugin::FilterRand do
  context "It should be rand" do
    subject { rand_plugin }

    describe "#run" do
      its(:run) { should have(1).feeds }

      # The contract is that the same items come back in some order. Asserting
      # a particular order would be asserting a particular shuffle, which was
      # what the previous version of this example did: it branched on the
      # outcome and fell through to a pending block on the one permutation in
      # twenty-four where nothing moved, so it failed at random.
      specify "returns exactly the input items" do
        subject.run
        links = subject.instance_variable_get(:@return_feeds)[0].items.map(&:link)
        links.sort.should == LINKS.sort
      end

      # That it shuffles at all is a statement about many runs, not one. With
      # four items there are twenty-four orders, so twenty runs landing on the
      # same one has a probability of about 24 * (1/24)**20.
      specify "does not always return the input order" do
        orders = 20.times.map { rand_plugin.run[0].items.map(&:link) }
        orders.uniq.length.should be > 1
      end
    end
  end
end
