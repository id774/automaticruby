# -*- coding: utf-8 -*-
# Name::      Automatic::StoreMock
# Updated::   Jun 14, 2012

module Automatic::Plugin
  class StoreMock
    def initialize(config, pipeline = [])
      @config = config
      @pipeline = pipeline
    end

    def run
      @pipeline[0]
    end
  end
end
