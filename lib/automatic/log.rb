# -*- coding: utf-8 -*-
# Name::        Automatic::Log
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 20, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# One log, to standard output, behind a level filter set per Recipe by
# global.log.level. See doc/BASIC_DESIGN.md section 4.7.

require 'logger'

module Automatic
  module Log
    # In increasing order of severity. 'none' is the threshold that admits
    # nothing; it is never used as the level of a message.
    LOG_LEVELS = %w[info warn error none].freeze

    DEFAULT_LEVEL = 'info'

    class << self
      # Set the threshold. An unrecognised name, including nil, means the
      # default: an unattended run should not be silenced by a typo in a
      # Recipe, nor should it raise in the middle of a job.
      def level(level = nil)
        @level = normalize(level, DEFAULT_LEVEL)
      end

      def logger
        @logger ||= Logger.new($stdout)
      end

      # Replace the logger. Used by the specs; a plugin has no business
      # calling this.
      attr_writer :logger

      # Emit a message at the given level, if the threshold admits it.
      # Both 'info' and :info are accepted, because plugins pass both.
      def puts(level, message)
        name = normalize(level, DEFAULT_LEVEL)
        return if name == 'none'
        return if LOG_LEVELS.index(name) < LOG_LEVELS.index(current_level)

        logger.public_send(name, message)
      end

      private

      def current_level
        @level ||= DEFAULT_LEVEL
      end

      def normalize(level, fallback)
        name = level.to_s
        LOG_LEVELS.include?(name) ? name : fallback
      end
    end
  end
end
