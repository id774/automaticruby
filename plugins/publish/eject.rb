# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::Eject
# Author:       soramugi (More info: http://soramugi.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Jun  9, 2013
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

module Automatic::Plugin
  class PublishEject
    # The command that opens the tray and the command that closes it again,
    # per platform, as argument vectors. Nothing here goes through a shell.
    COMMANDS = {
      'eject'  => [%w[eject], %w[eject -t]],           # GNU/Linux
      'drutil' => [%w[drutil tray eject], %w[drutil tray close]] # macOS
    }.freeze

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Opens and closes the optical drive once per item. A physical
    # notification, and the plugin that needs a machine with a tray.
    def run
      @pipeline.each do |feeds|
        next if feeds.nil?

        feeds.items.each do |feed|
          next if feed.link.nil?

          eject
          Automatic::Log.puts('info', "Eject: #{feed.link}")
          sleep(@config['interval'].to_i)
        end
      end
      @pipeline
    end

    private

    def eject
      commands = COMMANDS[command_name]
      if commands.nil?
        Automatic::Log.puts('warn', 'No eject command found on this system.')
        return
      end

      commands.each { |command| system(*command) }
    end

    # Looked up on PATH rather than by running `which` in a shell.
    def command_name
      @command_name ||= COMMANDS.keys.find { |name| executable?(name) }
    end

    def executable?(name)
      ENV['PATH'].to_s.split(File::PATH_SEPARATOR).any? do |dir|
        File.executable?(File.join(dir, name))
      end
    end
  end
end
