# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Extract::Twitter
# Author::    774 <http://id774.net>
# Created::   Sep  9, 2012
# Updated::   Sep  9, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class ExtractTwitter
    require 'nokogiri'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_html = []
      @pipeline.each {|html|
        unless html.nil?
          doc = Nokogiri::HTML(html)
          doc.xpath("/html/body/div").search('[@class="content"]').each {|content|
            arr = []
            # Screen name
            arr << content.search('[@class="username js-action-profile-name"]').text.to_s
            # Full name
            arr << content.search('[@class="fullname js-action-profile-name show-popup-with-id"]').text.to_s
            # User id
            content.search('[@class="account-group js-account-group js-action-profile js-user-profile-link js-nav"]').each {|node|
              arr << node['data-user-id'].to_s
            }
            # Permalink
            content.search('[@class="tweet-timestamp js-permalink js-nav"]').each {|node|
              arr << "http://twitter.com" + node['href'].to_s
            }
            # Time
            content.search('[@class="_timestamp js-short-timestamp js-relative-timestamp"]').each {|node|
              arr << node['data-time'].to_s
            }
            # Tweet
            arr << content.search('[@class="js-tweet-text"]').text.to_s
            @return_html << arr
          }
        end
      }
      @return_html
    end
  end
end
