#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class FilterIgnore
  def initialize(config, pipeline=[])
    @config = config
    @pipeline = pipeline
  end

  def exclude(link)
    detection = false
    @config['exclude'].each {|e|
      detection = true if link.include?(e.chomp)
    }
    if detection
      Log.puts("info", "Excluded: #{link}")
    end
    return detection
  end

  def run
    targets = []
    @pipeline.each {|links|
      target = []
      links.each {|link|
        target << link unless exclude(link)
      }
      targets << target
    }
    targets
  end
end
