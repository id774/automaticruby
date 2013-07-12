# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::ScrapingTumblr
# Author::    774 <http://id774.net>
# Created::   Jun  2, 2013
# Updated::   Jun  2, 2013
# Copyright:: 774 Copyright (c) 2012-2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class SubscriptionScrapingTumblr
    require 'open-uri'
    require 'nokogiri'
    require 'rss'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      @return_feeds = []
      @config['urls'].each {|url|
        retries = 0
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
          sleep @config['interval'].to_i unless @config['interval'].nil?
          retry if retries <= @config['retry'].to_i unless @config['retry'].nil?
        end
      }
      @return_feeds
    end

    private
    def create_rss(url)
      Automatic::Log.puts("info", "Parsing: #{url}")
      html = open(url).read
      unless html.nil?
        rss = RSS::Maker.make("2.0") {|maker|
          xss = maker.xml_stylesheets.new_xml_stylesheet
          xss.href = "http://tumblr.com"
          maker.channel.about = "http://tumblr.com"
          maker.channel.title = "tumblr"
          maker.channel.description = "tumblr"
          maker.channel.link = "http://tumblr.com/"
          maker.items.do_sort = true
          doc = Nokogiri::HTML(html)
          doc.xpath("/html/body/div").each {|content|
            content.search('[@class="span-12 prepend-5 maincontent"]').each {|node|
              node.xpath(".//a").each {|node_a|
                node_a.xpath(".//img").each {|node_img|
                  item = maker.items.new_item
                  item.title = "url"
                  item.link = node_img.attributes["src"].value
                  item.description = "The Scraping Tumblr Feed"
                }
              }
            }
          }
        }
        sleep @config['interval'].to_i unless @config['interval'].nil?
        @return_feeds << rss
      end
    end
  end
end
