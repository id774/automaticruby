# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "automatic"
  s.version = ""

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["id774"]
  s.date = "2012-03-07"
  s.description = "Ruby General Automation Framework"
  s.email = "idnanashi@gmail.com"
  s.executables = [".gitkeep", "automatic"]
  s.extra_rdoc_files = [
    "README.md",
    "README.txt"
  ]
  s.files = [
    "Gemfile",
    "README.md",
    "Rakefile",
    "VERSION",
    "app.rb",
    "automatic.gemspec",
    "bin/automatic",
    "config/default.yml",
    "config/feed2console.yml",
    "db/.gitkeep",
    "doc/COPYING",
    "doc/ChangeLog",
    "doc/PLUGINS.ja",
    "doc/README.ja",
    "lib/automatic.rb",
    "lib/automatic/environment.rb",
    "lib/automatic/feed_parser.rb",
    "lib/automatic/log.rb",
    "lib/automatic/pipeline.rb",
    "lib/automatic/recipe.rb",
    "lib/config/validator.rb",
    "plugins/custom_feed/svn_log.rb",
    "plugins/filter/ignore.rb",
    "plugins/filter/image.rb",
    "plugins/filter/tumblr_resize.rb",
    "plugins/notify/ikachan.rb",
    "plugins/publish/console.rb",
    "plugins/publish/google_calendar.rb",
    "plugins/publish/hatena_bookmark.rb",
    "plugins/store/full_text.rb",
    "plugins/store/permalink.rb",
    "plugins/store/store_database.rb",
    "plugins/store/target_link.rb",
    "plugins/subscription/feed.rb",
    "script/bootstrap",
    "spec/plugins/custom_feed/svn_log_spec.rb",
    "spec/plugins/filter/ignore_spec.rb",
    "spec/plugins/filter/image_spec.rb",
    "spec/plugins/filter/tumblr_resize_spec.rb",
    "spec/plugins/notify/ikachan_spec.rb",
    "spec/plugins/publish/console_spec.rb",
    "spec/plugins/publish/google_calendar_spec.rb",
    "spec/plugins/publish/hatena_bookmark_spec.rb",
    "spec/plugins/store/full_text_spec.rb",
    "spec/plugins/store/permalink_spec.rb",
    "spec/plugins/store/target_link_spec.rb",
    "spec/plugins/subscription/feed_spec.rb",
    "spec/spec_helper.rb",
    "test/integration/test_activerecord.yml",
    "test/integration/test_fulltext.yml",
    "test/integration/test_hatenabookmark.yml",
    "test/integration/test_ignore.yml",
    "test/integration/test_ignore2.yml",
    "test/integration/test_image2local.yml",
    "test/integration/test_svnlog.yml",
    "test/integration/test_tumblr2local.yml",
    "utils/auto_discovery.rb",
    "utils/opml_parser.rb",
    "vendor/.gitkeep"
  ]
  s.homepage = "http://github.com/id774/automaticruby"
  s.licenses = ["GPL"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.17"
  s.summary = "Automatic Ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sqlite3>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, ["~> 3"])
      s.add_runtime_dependency(%q<hashie>, [">= 0"])
      s.add_runtime_dependency(%q<activerecord>, ["~> 3"])
      s.add_runtime_dependency(%q<gcalapi>, [">= 0"])
      s.add_runtime_dependency(%q<xml-simple>, [">= 0"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.3"])
    else
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<activesupport>, ["~> 3"])
      s.add_dependency(%q<hashie>, [">= 0"])
      s.add_dependency(%q<activerecord>, ["~> 3"])
      s.add_dependency(%q<gcalapi>, [">= 0"])
      s.add_dependency(%q<xml-simple>, [">= 0"])
      s.add_dependency(%q<cucumber>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.3"])
    end
  else
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<activesupport>, ["~> 3"])
    s.add_dependency(%q<hashie>, [">= 0"])
    s.add_dependency(%q<activerecord>, ["~> 3"])
    s.add_dependency(%q<gcalapi>, [">= 0"])
    s.add_dependency(%q<xml-simple>, [">= 0"])
    s.add_dependency(%q<cucumber>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.3"])
  end
end

