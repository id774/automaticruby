# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::DescriptionLink
# Author::    774 <http://id774.net>
# Created::   Oct 03, 2014
# Updated::   Oct 16, 2014
# Copyright:: Copyright (c) 2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterDescriptionLink
    require 'uri'
    require 'nkf'

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
            new_feeds << rewrite_link(feed)
          }
        end
        @return_feeds << Automatic::FeedMaker.create_pipeline(new_feeds)
      }
      @return_feeds
    end

    private

    def get_title(url)
      new_title = nil
      if url.class == String
        url.gsub!(Regexp.new("[^#{URI::PATTERN::ALNUM}\/\:\?\=&~,\.\(\)#]")) {|match| ERB::Util.url_encode(match)}
        begin
          read_data = NKF.nkf("--utf8", open(url).read)
          get_text = Nokogiri::HTML.parse(read_data, nil, 'utf8').xpath('//title').text
          new_title = get_text if get_text.class == String
        rescue
          Automatic::Log.puts("warn", "Failed in get title for: #{url}")
        end
      end

      new_title
    end

    def rewrite_link(feed)
      new_link = URI.extract(feed.description, %w{http https}).uniq.last
      feed.link = new_link unless new_link.nil?

      if @config.class == Hash
        if @config['clear_description'] == 1
          feed.description = ""
        end

        if @config['get_title'] == 1
          begin
            new_title = get_title(feed.link)
            feed.title = new_title unless new_title.nil?
          rescue OpenURI::HTTPError
            Automatic::Log.puts("warn", "404 Not Found in get title process.")
          end
        end
      end

      feed
    end
  end
end

