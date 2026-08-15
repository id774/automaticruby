# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Subscription::Xml
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jul 12, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class SubscriptionXml
    require 'active_support/core_ext/hash/conversions'
    require 'json'

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    def run
      Array(@config['urls']).each_with_object([]) do |url, feeds|
        rss = fetch(url)
        feeds << rss unless rss.nil?
      end
    end

    private

    def fetch(url)
      retries   = 0
      retry_max = @config['retry'].to_i
      begin
        Automatic::Log.puts('info', "Parsing XML: #{url}")
        rss = Automatic::FeedMaker.content_provide(url, document(url))
        sleep(@config['interval'].to_i)
        rss
      rescue StandardError => e
        retries += 1
        Automatic::Log.puts('error',
                            "ErrorCount: #{retries}, Fault in parsing: #{url}, #{e.message}")
        return nil if retries > retry_max

        sleep(@config['interval'].to_i)
        retry
      end
    end

    # The document as plain hashes, arrays and strings. The round trip through
    # JSON is what flattens what Hash.from_xml returns -- dates, times and
    # ActiveSupport's own string subclasses -- into the values a consumer such
    # as ProvideFluentd can serialize.
    def document(url)
      JSON.parse(Hash.from_xml(Automatic::Http.read(url)).to_json)
    end
  end
end
