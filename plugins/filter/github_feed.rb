# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::GithubFeed
# Author::    Kohei Hasegawa <http://github.com/banyan>
# Created::   Jun 6, 2013
# Updated::   Jun 6, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterGithubFeed

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @pipeline.each {|feeds|
        dummyFeeds = []
        unless feeds.nil?
          feeds.items.each {|feed|
            Automatic::Log.puts("info", "Invoked: FilterGithubFeed")
            dummy = Hashie::Mash.new
            dummy.title       = feed.title.content
            dummy.link        = feed.id.content
            dummy.description = feed.content.content
            dummyFeeds << dummy
          }
        end
        @return_feeds << Automatic::FeedParser.create(dummyFeeds)
      }
      @pipeline = @return_feeds
    end
  end
end
