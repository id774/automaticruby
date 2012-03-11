# -*- coding: utf-8 -*-
# Name::      Automatic::FeedParser
# Author::    774 <http://id774.net>
# Created::   Feb 19, 2012
# Updated::   Mar 11, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic
  module FeedParser
    require 'rss'
    require 'uri'

    def self.get_rss(url)
      begin
        unless url.nil?
          feed = URI.parse(url).normalize
          open(feed) { |http|
            response = http.read
            RSS::Parser.parse(response, false)
          }
        end
      rescue => e
        raise e
      end
    end
  end
end
