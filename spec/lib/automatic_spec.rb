# -*- coding: utf-8 -*-
# Name::      Automatic::Ruby
# Author::    kzgs
#             774 <http://id774.net>
# Created::   Mar  9, 2012
# Updated::   Oct 23, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

require 'automatic'

describe Automatic do
  describe "#run" do
    describe "with a root dir which has default recipe" do
      subject {
          Automatic.run(:recipe   => "",
                        :root_dir => APP_ROOT,
                        :user_dir => APP_ROOT + "/spec/user_dir")
      }

      it { expect { subject }.to raise_error }
    end
  end

  describe "#version" do
    subject { Automatic.const_get(:VERSION) }

    it { expect(subject).to eq "14.10.1" }
  end

  describe "#(root)_dir" do
    subject { Automatic.root_dir }

    it { expect(subject).to eq APP_ROOT }

  end

  describe "#(config)_dir" do
    subject { Automatic.config_dir }

    it { expect(subject).to eq APP_ROOT+"/config" }
  end

  describe "#user_dir= in test env" do
    before(:all) do
      Automatic.user_dir = File.join(APP_ROOT, "spec/user_dir")
    end

    describe "#user_dir" do
      subject { Automatic.user_dir }

      it "return valid value" do
        expect(subject).to eq File.join(APP_ROOT, "spec/user_dir")
      end
    end

    describe "#user_plugins_dir" do
      subject { Automatic.user_plugins_dir }

      it "return valid value" do
        expect(subject).to eq File.join(APP_ROOT, "spec/user_dir/plugins")
      end
    end

    after(:all) do
      Automatic.user_dir = nil
    end
  end

  describe "#set_user_dir in other env" do
    before(:all) do
      ENV["AUTOMATIC_RUBY_ENV"] = "other"
      Automatic.user_dir = nil
    end

    describe "#user_dir" do
      subject { Automatic.user_dir }

      it "return valid value" do
        expect(subject).to eq File.expand_path("~/") + "/.automatic"
      end
    end

    describe "#user_plugins_dir" do
      subject { Automatic.user_plugins_dir }

      it "return valid value" do
        expect(subject).to eq File.expand_path("~/") + "/.automatic/plugins"
      end
    end

    after(:all) do
      ENV["AUTOMATIC_RUBY_ENV"] = "test"
    end
  end

end
