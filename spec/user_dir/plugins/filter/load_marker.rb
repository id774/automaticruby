# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::FilterLoadMarker
# Author:       id774 (More info: https://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Sep  6, 2026
# Updated::     Sep  6, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# A plugin with no behaviour of its own: this file's only purpose is to be
# discoverable so that spec/lib/automatic/pipeline_spec.rb can tell "the
# module is registered for autoload" apart from "the file has actually been
# read", by checking $LOADED_FEATURES for this path rather than by touching
# the constant, which would load it and defeat the point.

module Automatic::Plugin
  class FilterLoadMarker
    def initialize(config, pipeline = [])
      @pipeline = pipeline
    end

    def run
      @pipeline
    end
  end
end
