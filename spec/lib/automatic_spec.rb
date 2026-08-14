# -*- coding: utf-8 -*-
# Name::        Automatic::Ruby
# Author:       kzgs
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar  9, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

require 'automatic'

describe Automatic do
  describe "#run" do
    describe "without a recipe" do
      subject {
        Automatic.run(:recipe   => nil,
                      :root_dir => APP_ROOT,
                      :user_dir => APP_ROOT + "/spec/user_dir")
      }

      it { expect { subject }.to raise_error Automatic::NoRecipeError }
    end
  end

  describe "#version" do
    subject { Automatic.const_get(:VERSION) }

    # The VERSION file and the constant are one number recorded twice, and
    # doc/POLICY.md section 10.2 requires them to be changed together. This
    # asserts that they agree rather than pinning a literal.
    it "agrees with the VERSION file" do
      expect(subject).to eq File.read(File.join(APP_ROOT, "VERSION")).strip
    end

    it "is a year.month release number" do
      expect(subject).to match(/\A\d{2}\.\d{2}(\.\d+)?\z/)
    end
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

  # How a plugin requires a gem that only it needs. The framework's own
  # dependencies are not required this way; these are the optional ones, which
  # the operator who uses the plugin installs (doc/POLICY.md section 9.1).
  describe "#require_optional" do
    it "requires the library, as require does" do
      expect {
        Automatic.require_optional("tmpdir", needed_by: "a spec")
      }.not_to raise_error
      expect(defined?(Dir.mktmpdir)).to eq "method"
    end

    it "names the gem, what needs it and how to install it when it is absent" do
      expect {
        Automatic.require_optional("automatic_no_such_gem", needed_by: "FilterExample")
      }.to raise_error(LoadError, /`automatic_no_such_gem` gem is not installed/)
    end

    it "reports the gem's name where it differs from the path required" do
      expect {
        Automatic.require_optional("automatic_no_such_gem",
                                   gem_name: "automatic-no-such-gem",
                                   needed_by: "CustomFeedExample")
      }.to raise_error(LoadError, /gem install automatic-no-such-gem/)
    end

    it "names what needed it" do
      expect {
        Automatic.require_optional("automatic_no_such_gem", needed_by: "FilterExample")
      }.to raise_error(LoadError, /needed by FilterExample/)
    end
  end

end
