# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::Weather
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   May  12, 2013
# Updated::   Aug 14, 2026
# Copyright:: Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

# livedoor Weather Hacks was terminated in 2020;
# doc/PLUGINS.md section 6.1 classifies SubscriptionWeather as Unsupported.
#
# The gem is not a dependency of this project, so this spec is skipped rather
# than stubbed; see doc/POLICY.md section 4.
return unless AutomaticSpec.plugin_available?('subscription/weather')

describe Automatic::Plugin::SubscriptionWeather do
  context "with empty zipcode" do
    subject {
      Automatic::Plugin::SubscriptionWeather.new(
        {}
      )
    }

    its(:run) { should be_empty }
  end

  context "with zipcode whose return feed" do
    subject {
      Automatic::Plugin::SubscriptionWeather.new(
        { 'zipcode' => '166-0003' }
      )
    }

    its(:run) { should have(1).feed }
  end

  context "with zipcode and day whose return feed" do
    subject {
      Automatic::Plugin::SubscriptionWeather.new(
        { 'zipcode' => '166-0003', 'day' => 'tomorrow' }
      )
    }

    its(:run) { should have(1).feed }
  end

end
