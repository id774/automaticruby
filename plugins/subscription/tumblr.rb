# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Tumblr
# Author::    774 <http://id774.net>
# Created::   Oct 16, 2012
# Updated::   Feb 21, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionTumblr
    require 'open-uri'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @config['urls'].each {|url|
        retries = 0
        retry_max = @config['retry'].to_i || 0
        begin
          create_rss(url)
          unless @config['pages'].nil?
            @config['pages'].times {|i|
              if i > 0
                old_url = url + "/page/" + (i+1).to_s
                create_rss(old_url)
              end
            }
          end
        rescue
          retries += 1
          Automatic::Log.puts("error", "ErrorCount: #{retries}, Fault in parsing: #{url}")
          sleep ||= @config['interval'].to_i
          retry if retries <= retry_max
        end
      }
      @return_feeds
    end

    private
    def create_rss(url)
      Automatic::Log.puts("info", "Parsing: #{url}")
      html = open(url).read
      unless html.nil?
        uri = URI.parse(url)
        rss = Automatic::FeedParser.parse_html(html)
        rss.items.each {|item|
           unless item.link =~ Regexp.new(uri.host)
             item.link = nil
           end
        }
        sleep ||= @config['interval'].to_i
        @return_feeds << rss
      end
    end
  end
end
