# -*- coding: utf-8 -*-
# Name::        Automatic::Environment
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 18, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# Bundler setup for a source checkout, and nothing more.
#
# When this repository is used from a checkout, bin/automatic should resolve
# the gems the checkout's Gemfile locks. When the gem is installed normally
# there is no Gemfile beside lib/, this file does nothing, and that is correct:
# an installed library must not impose a bundle on the program requiring it.
#
# This deliberately does not call Bundler.require. Loading every gem in the
# bundle is how a plugin's dependency used to become everyone's; see
# doc/POLICY.md section 2.5.

gemfile = File.expand_path('../../Gemfile', __dir__)

if File.exist?(gemfile)
  ENV['BUNDLE_GEMFILE'] ||= gemfile
  begin
    require 'bundler/setup'
  rescue LoadError, StandardError
    # Bundler is absent, or the bundle is not installed. Fall back to whatever
    # RubyGems can activate; a genuinely missing dependency will surface as a
    # LoadError naming it, which is the more useful message anyway.
    nil
  end
end
