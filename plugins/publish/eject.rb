# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Eject
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun  9, 2013
# Updated::     May 16, 2014
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishEject

    def initialize(config, pipeline=[])
      @config   = config
      @pipeline = pipeline
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            unless feed.link.nil?
              `#{eject_cmd}`
              Automatic::Log.puts('info', "Eject: #{feed.link}")

              interval = @config['interval'].to_i unless @config['interval'].nil? unless @config.nil?
              sleep ||= @config['interval'].to_i
            end
          }
        end
      }
      @pipeline
    end

    def eject_cmd
      if `which eject` != '' # linux
        'eject ; eject -t'
      elsif `which drutil` != '' # mac
        'drutil tray eject ; drutil tray close'
      end
    end
  end
end
