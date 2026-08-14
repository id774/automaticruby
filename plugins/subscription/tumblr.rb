# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Tumblr
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Oct 16, 2012
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

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
      Automatic::Log.puts("info", "Parsing Tumblr: #{url}")
      html = URI.open(url).read
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
