# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::GithubFeed
# Author:       Kohei Hasegawa (More info: http://github.com/banyan)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun  6, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterGithubFeed
    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Converts Atom entries -- where title, id and content are elements with a
    # #content -- into the flat items the rest of the pipeline expects. Needed
    # because GitHub publishes Atom, not RSS.
    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        items = feeds.nil? ? [] : feeds.items.map { |item| flatten(item) }
        returned << Automatic::FeedMaker.create_pipeline(items)
      end
    end

    private

    def flatten(item)
      Automatic::Log.puts('info', 'Invoked: FilterGithubFeed')
      entry             = Hashie::Mash.new
      entry.title       = value(item, :title)
      entry.link        = value(item, :id)
      entry.description = value(item, :content)
      entry
    end

    # An Atom element carries its text in #content; a field that is already a
    # string is used as it stands, so that a pipeline which has been through
    # another filter first is not a NoMethodError.
    def value(item, name)
      return nil unless item.respond_to?(name)

      field = item.send(name)
      field.respond_to?(:content) ? field.content : field
    end
  end
end
