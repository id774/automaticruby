# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Clear
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Oct 20, 2014
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class FilterClear
    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Returns an empty pipeline, to end a Recipe after a store plugin has done
    # the work so that later plugins publish nothing.
    def run
      []
    end
  end
end
