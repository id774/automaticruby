# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Clear
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Oct 20, 2014
# Updated::   Oct 20, 2014
# Copyright:: Copyright (c) 2014 Automatic Ruby Developers.

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
