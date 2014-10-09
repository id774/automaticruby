# -*- coding: utf-8 -*-
# Name::      Automatic::Log
# Author::    774 <http://id774.net>
# Created::   Feb 20, 2012
# Updated::   Oct 09, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require 'logger'

module Automatic
  module Log
    LOG_LEVELS = ['info', 'warn', 'error', 'none']

    def self.level(level)
      @level = level
    end

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.puts(level = :info, message)
      if LOG_LEVELS.index(@level).to_i > LOG_LEVELS.index(level).to_i
        return
      end
      logger.send(level, message)
    end

  end
end
