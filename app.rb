#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Ruby
# Author::    774 <http://id774.net>
# Version::   12.02-devel
# Created::   Feb 18, 2012
# Updated::   Feb 22, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

root_dir = File.expand_path(File.dirname(__FILE__))
$:.unshift root_dir
$:.unshift root_dir + '/lib'
require 'lib/automatic'

Automatic.run(root_dir)

