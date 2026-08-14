# -*- mode: ruby; coding: utf-8 -*-
# The runtime and development dependencies are declared in automatic.gemspec,
# which this file evaluates. Only the optional, plugin-specific gems are listed
# here. See doc/POLICY.md section 9.

source 'https://rubygems.org'

gemspec

# Optional dependencies, each needed by one plugin or a few. They are NOT
# runtime dependencies of the gem: installing automatic does not install them,
# and a Recipe that does not use the plugin does not need them.
#
# Uncomment what you use in a checkout. The table of which plugin needs which
# gem, and which of those plugins still work, is in doc/DEPLOYMENT.md and
# doc/PLUGINS.md section 6.
group :plugins, optional: true do
  # PublishAmazonS3 and the s3n:// path of StoreFile call AWS::S3, which only
  # AWS SDK for Ruby v1 provided. No currently published gem satisfies them, so
  # there is nothing to uncomment; they need rework. See doc/PLUGINS.md.
  # gem 'dalli'           # PublishMemcached
  # gem 'fluent-logger'   # PublishFluentd and ProvideFluentd
  # gem 'xml-simple'      # CustomFeedSVNLog
end
