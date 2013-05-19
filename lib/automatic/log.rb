# -*- coding: utf-8 -*-
# Name::      Automatic::Log
# Author::    774 <http://id774.net>
# Created::   Feb 20, 2012
# Updated::   Mar 11, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic
  module Log
    LOG_LEVELS = ['info', 'warn', 'error']

    def self.level(level)
      @level = level
    end

    def self.puts(level, message)
      if LOG_LEVELS.index(@level).to_i > LOG_LEVELS.index(level).to_i
        return
      end
      t = Time.now.strftime("%Y/%m/%d %X")
      print log = "#{t} [#{level}] #{message}\n"
      return log
    end
  end
end
