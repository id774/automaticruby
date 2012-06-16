# -*- coding: utf-8 -*-
# Name::      Auaotmatic::Recipe
# Author::    774 <http://id774.net>
# Created::   Jun 14, 2012
# Updated::   Jun 14, 2012
# Copyright:: ainame Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

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

    describe "with a normal recipe" do
      it "correctly load recipe" do
        recipe = Automatic::Recipe.new(TEST_RECIPE)
        expect =[{"module"=>"SubscriptionFeed",
          "config"=>{"feeds"=>["http://blog.id774.net/post/feed/"]}},
          {"module"=>"FilterIgnore", "config"=>{"link"=>["hoge"]}},
          {"module"=>"StorePermalink", "config"=>{"db"=>"test_permalink.db"}}]
        recipe.each_plugin{recipe}.should == expect
      end
    end

  end
end
