# -*- coding: utf-8 -*-

require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

require 'yaml'

RSpec.describe 'the feed2markdown example Recipe' do
  let(:path) { File.join(APP_ROOT, 'config', 'feed2markdown.yml') }
  let(:recipe) { YAML.safe_load(File.read(path)) }

  it 'uses the short supported pipeline its header documents' do
    modules = recipe.fetch('plugins').map { |plugin| plugin.fetch('module') }
    expect(modules).to eq %w[SubscriptionFeed PublishMarkdown]
  end

  # This is the shipped Recipe a plain `gem install automatic` can run with
  # nothing added, which is what makes it the one to reach for first, so it
  # names no plugin that needs an optional gem. The store plugins, which do,
  # are the documented next step rather than the first one. See
  # doc/POLICY.md section 9.1.
  it 'names no plugin that needs an optional dependency' do
    modules = recipe.fetch('plugins').map { |plugin| plugin.fetch('module') }
    expect(modules).not_to include('StorePermalink', 'StoreFullText')
  end

  it 'uses a public HTTPS source and needs no credential' do
    source = recipe.fetch('plugins').first.fetch('config').fetch('feeds').first
    expect(source).to start_with('https://')
    expect(recipe.to_s).not_to match(/password|token|api[_-]?key/i)
  end

  it 'names plugins that ship at their loader-derived paths' do
    recipe.fetch('plugins').each do |plugin|
      underscored = plugin.fetch('module').underscore
      category, name = underscored.split('_', 2)
      expect(File).to exist(File.join(APP_ROOT, 'plugins', category, "#{name}.rb"))
    end
  end

  it 'writes the Markdown file its header describes' do
    publisher = recipe.fetch('plugins').last.fetch('config')
    expect(publisher).to include(
      'file' => '~/.automatic/markdown/feeds.md',
      'mode' => 'append'
    )
  end
end
