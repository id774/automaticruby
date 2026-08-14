# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::ConsoleLink
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Jun 02, 2013
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishConsoleLink
    require 'pp'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
      @output = $stdout
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            @output.puts(feed.link)
          }
        end
      }
      @pipeline
    end
  end
end
