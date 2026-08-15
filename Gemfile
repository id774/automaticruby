# -*- mode: ruby; coding: utf-8 -*-
# The runtime and development dependencies are declared in automatic.gemspec,
# which this file evaluates. Only the optional, plugin-specific gems are listed
# here. See doc/POLICY.md section 9.
#
# `bundle install` with no configuration installs the framework's four runtime
# dependencies and the development ones, and nothing below: a checkout is set
# up to run and to test the framework, not to run every plugin.

source 'https://rubygems.org'

gemspec

# Optional dependencies, each needed by one plugin or a few. They are NOT
# runtime dependencies of the gem: installing automatic does not install them,
# and a Recipe that does not use the plugin does not need them.
#
# Every group here is optional, so nothing below is installed by default and
# neither the default test suite nor required CI depends on any of it. Each gem
# is in two groups: `plugins`, which is all of them at once, and one named
# after what it is for, which is one of them on its own. Both are Bundler
# groups and both are selected the same way, in the checkout's own .bundle
# directory, which is not committed:
#
#   bundle config set --local with plugins     # all of the below
#   bundle config set --local with store       # activerecord and sqlite3 only
#   bundle config set --local with "store html"
#   bundle install
#
# Setting it in the configuration rather than passing BUNDLE_WITH to one
# command is what makes the gems visible to `bundle exec` afterwards, so the
# specs of the plugins that need them then run as part of the ordinary suite.
# `bundle config unset --local with` returns the checkout to the minimum.
#
# The table of which plugin needs which gem, and which of those plugins still
# work, is in doc/DEPLOYMENT.md and doc/PLUGINS.md section 6.

# StorePermalink and StoreFullText, through plugins/store/database.rb.
group :plugins, :store, optional: true do
  gem 'activerecord', '>= 7.1', '< 9.0'
  gem 'sqlite3',      '>= 1.7', '< 3.0'
end

# An HTML parser, for the plugins that read HTML: FilterFullFeed,
# FilterImageSource, FilterDescriptionLink, and FeedParser.parse_html for
# SubscriptionLink and SubscriptionTumblr. PublishMarkdown uses it when it is
# installed and reduces a body to text without it.
group :plugins, :html, optional: true do
  gem 'nokogiri', '>= 1.15', '< 2.0'
end

# FilterSanitize.
group :plugins, :sanitize, optional: true do
  gem 'sanitize'
end

# The autodiscovery and inspect subcommands. No plugin and no Recipe uses it.
group :plugins, :autodiscovery, optional: true do
  gem 'feedbag', '>= 1.0', '< 2.0'
end

# The plugins below are Supported (external): each needs a service or a command
# the operator provides, and their specs exercise it rather than a double. They
# are deliberately outside the `plugins` group, so that installing that group
# leaves the suite runnable with nothing else set up. Select one of these by
# its own name when you have what it talks to.
group :memcached, optional: true do
  gem 'dalli'             # PublishMemcached, with a memcached server
end

group :fluentd, optional: true do
  gem 'fluent-logger'     # PublishFluentd and ProvideFluentd, with a Fluentd instance
end

group :s3, optional: true do
  gem 'aws-sdk-s3'        # PublishAmazonS3 and the s3 path of StoreFile, with a bucket
end

# CustomFeedSVNLog needs the svn command and no gem: it reads `svn log --xml`
# with REXML, which is a runtime dependency of the framework already.
