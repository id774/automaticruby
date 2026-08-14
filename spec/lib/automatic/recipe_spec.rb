# -*- coding: utf-8 -*-
# Name::        Auaotmatic::Recipe
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun 14, 2012
# Updated::     Jun 14, 2012
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.join(File.dirname(__FILE__) ,'../../spec_helper'))
require 'automatic'
require 'automatic/recipe'

TEST_RECIPE =  File.expand_path(File.join(APP_ROOT, "spec",
  'fixtures', 'sampleRecipe.yml'))

describe Automatic::Recipe do
  describe "with recipe" do
    before do
      Automatic.root_dir = File.expand_path(File.join(File.dirname(__FILE__), "../../../"))
      Automatic.user_dir = nil
    end

    context "with a normal recipe" do
      subject {
        recipe = Automatic::Recipe.new(TEST_RECIPE)
        recipe.each_plugin{recipe}
      }
      let(:expected) { [{"module"=>"SubscriptionFeed",
        "config"=>{"feeds"=>["http://blog.id774.net/post/feed/"]}},
        {"module"=>"FilterIgnore", "config"=>{"link"=>["hoge"]}},
        {"module"=>"StorePermalink", "config"=>{"db"=>"test_permalink.db"}}]
      }

      it "correctly load recipe" do
        expect(subject).to eq expected
      end
    end

  end
end
