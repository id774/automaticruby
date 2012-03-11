# -*- coding: utf-8 -*-
# Name::      Automatic::Log
# Author::    774 <http://id774.net>
# Created::   Feb 20, 2012
# Updated::   Mar 11, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic
  module Log
    def self.puts(level, message)
      t = Time.now.strftime("%Y/%m/%d %X")
      print "#{t} [#{level}] #{message}\n"
    end
  end
end
