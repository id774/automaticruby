# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Subscription::weather
# Author::    soramugi <http://soramugi.net>
# Created::   May  12, 2013
# Updated::   May  12, 2013
# Copyright:: soramugi Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/weather'

describe Automatic::Plugin::SubscriptionWeather do
  context "with empty zipcode" do
    subject {
      Automatic::Plugin::SubscriptionWeather.new(
        { }
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

  context "with retry to feeds whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionWeather.new(
        { 'zipcode' => [],
          'retry' => 1,
          'interval' => 1
        }
      )
    }

    its(:run) { should be_empty }
  end

end
