# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::GithubFeed
# Author::    Kohei Hasegawa <http://github.com/banyan>
#             774 <http://id774.net>
# Created::   Jun  6, 2013
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
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
