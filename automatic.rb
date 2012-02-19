#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$:.unshift File.join(File.dirname(__FILE__))
$:.unshift File.join(File.dirname(__FILE__), 'lib')
$:.unshift File.join(File.dirname(__FILE__), 'plugins')

require "auto_bookmark"
a = AutoBookmark.new
a.bookmark
