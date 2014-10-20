# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Clear
# Author::    774 <http://id774.net>
# Created::   Oct 20, 2014
# Updated::   Oct 20, 2014
# Copyright:: Copyright (c) 2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class FilterClear
    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      []
    end
  end
end
