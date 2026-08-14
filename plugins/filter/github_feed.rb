# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::GithubFeed
# Author:       Kohei Hasegawa (More info: http://github.com/banyan)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun  6, 2013
# Updated::     Feb 21, 2014
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterGithubFeed

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        new_feeds = []
        unless feeds.nil?
          feeds.items.each {|feed|
            Automatic::Log.puts("info", "Invoked: FilterGithubFeed")
            hashie = Hashie::Mash.new
            hashie.title       = feed.title.content
            hashie.link        = feed.id.content
            hashie.description = feed.content.content
            new_feeds << hashie
          }
        end
        @return_feeds << Automatic::FeedMaker.create_pipeline(new_feeds)
      }
      @return_feeds
    end
  end
end
