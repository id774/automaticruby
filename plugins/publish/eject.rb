# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Eject
# Author::    soramugi <http://soramugi.net>
# Created::   Jun  9, 2013
# Updated::   Jan 15, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

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
      if `type -P eject` != '' # linux
        'eject ; eject -t'
      elsif `type -P drutil` != '' # mac
        'drutil tray eject ; drutil tray close'
      end
    end
  end
end
