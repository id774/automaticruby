#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$:.unshift File.join(File.dirname(__FILE__), 'lib')
$:.unshift File.join(File.dirname(__FILE__), 'plugins')

Dir.glob(File.dirname(__FILE__) + '/lib/*.rb').each {|r|
  require(File.basename(r, '.rb'))
}
Dir.glob(File.dirname(__FILE__) + '/plugins/*.rb').each {|r|
  require(File.basename(r, '.rb'))
}

config = YAML.load(File.open(File.dirname(__FILE__) + '/config/default.yml'))
loader = eval(config['plugins']['module']).new(config)
loader.run
