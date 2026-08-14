# -*- coding: utf-8 -*-
# Name::        Automatic::StoreMock
# Author:       ainame
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar 10, 2012
# Updated::     Jun 14, 2012
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

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
