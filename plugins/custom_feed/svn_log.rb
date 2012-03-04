# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::CustomFeed::SVNLog
# Author::    kzgs
# Created::   Feb 29, 2012
# Updated::   Mar  3, 2012
# Copyright:: kzgs Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'rss/maker'

module Automatic::Plugin
  class CustomFeedSVNLog
    require 'xmlsimple'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      revisions = XmlSimple.xml_in(`svn log #{svn_log_argument}`)["logentry"]
      @pipeline << RSS::Maker.make("1.0") { |maker|
        maker.channel.title = @config["title"] || ""
        maker.channel.about = ""
        maker.channel.description = ""
        maker.channel.link = base_url
        revisions.each { |rev|
          item = maker.items.new_item
          item.title = "#{rev["msg"]} by #{rev["author"]}"
          item.link = base_url+"/!svn/bc/#{rev["revision"]}"
          item.date = Time.parse(rev["date"][0])
        }
      }
      return @pipeline
    end

    private

    def base_url
      return @config['target'].gsub(/\/$/, "")
    end
    
    def svn_log_argument
      return [
        base_url,
        "--xml",
        "--limit=#{limit}"
      ].join(" ")
    end

    def limit
      return @config['fetch_items'] || 30
    end
  end
end

