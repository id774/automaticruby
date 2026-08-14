# -*- coding: utf-8 -*-
# Name::        Automatic::CLI
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 14, 2026
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# Everything that belongs to being a command: option parsing, the subcommands,
# and turning a failure into a message and an exit status.
#
# CLI.run returns an Integer and never calls exit. Deciding the process's fate
# is bin/automatic's job, and returning the status is what makes the command
# line testable without spawning a process. See doc/BASIC_DESIGN.md section 4.2.

require 'automatic'
require 'fileutils'
require 'optparse'

module Automatic
  class CLI
    EXIT_SUCCESS = 0
    EXIT_FAILURE = 1
    EXIT_USAGE   = 2

    # The installation root: the directory holding plugins/, config/ and db/.
    DEFAULT_ROOT_DIR = File.expand_path('../..', __dir__)

    def self.run(argv, **options)
      new(**options).run(argv)
    end

    def initialize(root_dir: DEFAULT_ROOT_DIR, stdout: $stdout, stderr: $stderr)
      @root_dir = root_dir
      @stdout   = stdout
      @stderr   = stderr
    end

    # Returns the process exit status. --help and --version, and a subcommand
    # invoked without its argument, finish early by throwing :automatic_exit.
    def run(argv)
      catch(:automatic_exit) do
        argv = argv.dup
        recipe_path = nil

        parser = build_parser { |path| recipe_path = path }

        begin
          parser.order!(argv)
        rescue OptionParser::ParseError => e
          @stderr.puts e.message
          @stderr.puts parser.help
          throw :automatic_exit, EXIT_USAGE
        end

        next run_recipe(recipe_path) unless recipe_path.to_s.empty?
        next usage(parser) if argv.empty?

        run_subcommand(argv)
      end
    end

    private

    SUBCOMMAND_USAGE = {
      'scaffold'      => '',
      'unscaffold'    => '',
      'autodiscovery' => '<url>',
      'feedparser'    => '<url>',
      'inspect'       => '<url>',
      'opmlparser'    => '<opml path>',
      'log'           => '<level> <message>'
    }.freeze

    def build_parser
      OptionParser.new do |parser|
        parser.version = Automatic::VERSION
        parser.banner = "Automatic Ruby #{Automatic::VERSION}\n" \
                        "    Usage: automatic [options] [subcommand]"
        parser.separator 'SubCommands:'
        SUBCOMMAND_USAGE.each do |name, arguments|
          parser.separator "    #{name} #{arguments}".rstrip
        end
        parser.separator 'Options:'
        parser.on('-c', '--config FILE', String, 'recipe YAML file') do |path|
          yield path
        end
        parser.on('-h', '--help', 'show this message') do
          @stdout.puts parser.help
          throw :automatic_exit, EXIT_SUCCESS
        end
        parser.on('-v', '--version', 'show the version') do
          @stdout.puts Automatic::VERSION
          throw :automatic_exit, EXIT_SUCCESS
        end
      end
    end

    def usage(parser)
      @stdout.puts parser.help
      EXIT_FAILURE
    end

    def run_recipe(path)
      unless File.exist?(resolve_recipe(path))
        @stderr.puts "automatic: no such recipe: #{path}"
        return EXIT_FAILURE
      end

      Automatic.run(recipe: Automatic::Recipe.new(path), root_dir: @root_dir)
      EXIT_SUCCESS
    rescue Automatic::Error, Psych::Exception, SystemCallError, IOError => e
      @stderr.puts "automatic: #{e.message}"
      EXIT_FAILURE
    end

    # Mirrors Automatic::Recipe's own resolution, so that a missing file is
    # reported as a message rather than as a backtrace.
    def resolve_recipe(path)
      in_user_dir = File.join(Automatic.user_config_dir, path.to_s)
      File.exist?(in_user_dir) ? in_user_dir : path.to_s
    end

    def run_subcommand(argv)
      name = argv.shift
      handler = subcommands[name]

      unless handler
        @stderr.puts "automatic: no such subcommand: #{name}"
        return EXIT_FAILURE
      end

      handler.call(argv)
      EXIT_SUCCESS
    rescue Automatic::Error, SystemCallError, IOError => e
      @stderr.puts "automatic: #{e.message}"
      EXIT_FAILURE
    end

    def missing_argument(name)
      @stderr.puts "Usage: automatic #{name} #{SUBCOMMAND_USAGE[name]}"
      throw :automatic_exit, EXIT_FAILURE
    end

    # Each subcommand requires what it needs, so that `automatic --version`
    # loads neither a feed parser nor an OPML parser.
    def subcommands
      {
        'scaffold'      => method(:scaffold),
        'unscaffold'    => method(:unscaffold),
        'autodiscovery' => method(:autodiscovery),
        'feedparser'    => method(:feedparser),
        'inspect'       => method(:inspect_url),
        'opmlparser'    => method(:opmlparser),
        'log'           => method(:log)
      }
    end

    def scaffold(_argv)
      Dir.children(File.join(@root_dir, 'plugins')).sort.each do |category|
        next unless File.directory?(File.join(@root_dir, 'plugins', category))

        create_dir(File.join(Automatic.user_dir, 'plugins', category))
      end

      create_dir(File.join(Automatic.user_dir, 'db'))

      assets = File.join(Automatic.user_dir, 'assets')
      if create_dir(assets)
        FileUtils.cp_r(File.join(@root_dir, 'assets', 'siteinfo'),
                       File.join(assets, 'siteinfo'))
      end

      config = Automatic.user_config_dir
      if create_dir(config)
        FileUtils.cp_r(File.join(@root_dir, 'config'),
                       File.join(config, 'example'))
      end
    end

    def unscaffold(_argv)
      dir = Automatic.user_dir
      return unless File.directory?(dir)

      @stdout.puts "Removing #{dir}"
      FileUtils.rm_r(dir)
    end

    def autodiscovery(argv)
      require 'feedbag'
      require 'pp'
      url = argv.shift || missing_argument('autodiscovery')
      @stdout.puts Feedbag.find(url).pretty_inspect
    end

    def feedparser(argv)
      require 'automatic/feed_parser'
      require 'pp'
      url = argv.shift || missing_argument('feedparser')
      @stdout.puts Automatic::FeedParser.get_url(url).pretty_inspect
    end

    def inspect_url(argv)
      require 'automatic/feed_parser'
      require 'feedbag'
      require 'pp'
      url = argv.shift || missing_argument('inspect')
      feeds = Feedbag.find(url)
      @stdout.puts feeds.pretty_inspect
      @stdout.puts Automatic::FeedParser.get_url(feeds.pop).pretty_inspect
    end

    def opmlparser(argv)
      require 'automatic/opml'
      path = argv.shift || missing_argument('opmlparser')
      parser = Automatic::OPML::Parser.new(File.read(path))
      parser.each_outline { |_opml, outline| @stdout.puts outline.xmlUrl }
    end

    def log(argv)
      level = argv.shift || missing_argument('log')
      message = argv.shift || missing_argument('log')
      Automatic::Log.puts(level, message)
    end

    def create_dir(path)
      return false if File.exist?(path)

      FileUtils.mkdir_p(path)
      @stdout.puts "Creating #{path}"
      true
    end
  end
end
