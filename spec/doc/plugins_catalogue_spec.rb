# -*- coding: utf-8 -*-
# Name::        The plugin catalogue
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 15, 2026
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# doc/PLUGINS.md section 6 is the catalogue of what ships, and README.md
# repeats its counts. Both are prose, and prose drifts from a directory. This
# holds them to it: a plugin with no entry, an entry with no plugin, and a
# count left behind by an edit are failures of the ordinary suite rather than
# something a reader discovers.

require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

RSpec.describe 'the plugin catalogue' do
  # Every plugin class the gem ships, from the files themselves. A file that
  # defines no plugin class -- store/database.rb, which is the storage the
  # store plugins share -- is not one and is named here.
  SHARED_FILES = ['store/database.rb'].freeze

  # A plugin file may define a helper class beside the plugin itself, so the
  # plugin is the class whose name maps back to the file the loader would find
  # it in -- which is the rule of section 3.2 applied in the other direction.
  def shipped_plugins
    Dir[File.join(APP_ROOT, 'plugins', '*', '*.rb')].flat_map { |path|
      relative = path.sub("#{File.join(APP_ROOT, 'plugins')}/", '')
      next [] if SHARED_FILES.include?(relative)

      expected = relative.sub(/\.rb\z/, '').tr('/', '_')
      names = File.read(path, encoding: 'UTF-8').scan(/^\s*class\s+([A-Z]\w*)/).flatten
      found = names.select { |name| name.underscore == expected }
      raise "#{relative} defines no class the loader would find" if found.empty?

      found
    }.sort
  end

  # "#### SubscriptionFeed — **Supported**"
  ENTRY = /^\#\#\#\#\s+(\w+)\s+—\s+\*\*(.+?)\*\*/

  def catalogue
    document = File.read(File.join(APP_ROOT, 'doc', 'PLUGINS.md'), encoding: 'UTF-8')
    section = document[/^## 6\. The plugins$.*?^## 7\./m]
    raise 'doc/PLUGINS.md has no section 6' if section.nil?

    section.scan(ENTRY).to_h
  end

  # "| Supported (external) | 10 | `SubscriptionTumblr`, ... |"
  def summary_rows
    document = File.read(File.join(APP_ROOT, 'doc', 'PLUGINS.md'), encoding: 'UTF-8')
    document.scan(/^\|\s(Supported|Supported \(external\)|Needs rework)\s\|\s(\d+)\s\|\s(.+?)\s\|$/)
  end

  let(:shipped) { shipped_plugins }
  let(:entries) { catalogue }

  # The loader resolves a name against the installation root, which a spec run
  # has not set.
  around do |example|
    root = Automatic.root_dir
    Automatic.root_dir = APP_ROOT
    example.run
    Automatic.root_dir = root
  end

  it 'has an entry for every plugin that ships' do
    (shipped - entries.keys).should == []
  end

  it 'ships a plugin for every entry, at its loader-derived path' do
    (entries.keys - shipped).should == []

    entries.each_key do |name|
      lambda { Automatic::Pipeline.load_plugin(name) }.should_not raise_error
    end
  end

  it 'gives every plugin one of the statuses section 5 defines' do
    entries.each_pair do |name, status|
      status.sub(/,.*\z/, '').should satisfy { |value|
        ['Supported', 'Supported (external)', 'Needs rework'].include?(value)
      }, "#{name} has the status #{status.inspect}"
    end
  end

  describe 'the summary table in section 7' do
    it 'counts what section 6 lists' do
      counted = entries.values.group_by { |status| status.sub(/,.*\z/, '') }.
                transform_values(&:size)

      summary_rows.each do |status, count, _plugins|
        count.to_i.should == counted.fetch(status, 0)
      end
    end

    it 'names what section 6 lists' do
      summary_rows.each do |status, _count, plugins|
        named = plugins.scan(/`(\w+)`/).flatten.sort
        expected = entries.select { |_name, value| value.sub(/,.*\z/, '') == status }.keys.sort
        named.should == expected
      end
    end

    it 'accounts for every plugin exactly once' do
      summary_rows.sum { |_status, count, _plugins| count.to_i }.should == shipped.size
    end
  end

  describe 'README.md' do
    let(:readme) { File.read(File.join(APP_ROOT, 'README.md'), encoding: 'UTF-8') }

    it 'gives the same total' do
      readme.should include("#{shipped.size} plugins")
    end

    it 'gives the same count per status' do
      summary_rows.each do |status, count, _plugins|
        readme.should match(/\*\*#{Regexp.escape(status)}\*\*\s*\|\s*#{count}\s*\|/)
      end
    end
  end
end
