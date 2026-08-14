# -*- coding: utf-8 -*-

module Automatic::Plugin
  class FilterTitlePrefix
    def initialize(config, pipeline = [])
      @config = config || {}
      @pipeline = pipeline
    end

    def run
      prefix = @config['prefix'].to_s
      @pipeline.each do |feed|
        next if feed.nil?

        feed.items.each do |item|
          item.title = "#{prefix}#{item.title}"
        end
      end
      @pipeline
    end
  end
end
