# -*- coding: utf-8 -*-
# Name::      Automatic
# Author::    kzgs
# Created::   Mar  9, 2012
# Updated::   Mar 10, 2012
# Copyright:: kzgs Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require 'automatic'

describe Automatic do
  describe "#run" do
    describe "with a root dir which has default recipe" do
      specify {
        lambda{ 
          Automatic.run(:recipe   => "",
                        :root_dir => APP_ROOT,
                        :user_dir => APP_ROOT + "/spec/user_dir")
        }.should_not raise_exception(Errno::ENOENT)
      }
    end
  end

  describe "#(root|config)_dir" do
    specify {
      Automatic.root_dir.should == APP_ROOT
      Automatic.config_dir.should == APP_ROOT+"/config"
    }
  end

  describe "#user_dir= in test env" do 
    before(:all) do
      Automatic.user_dir = File.join(APP_ROOT, "spec/user_dir")
    end

    describe "#user_dir" do
      it "return valid value" do
        Automatic.user_dir.should == File.join(APP_ROOT, "spec/user_dir")
      end
    end

    describe "#user_plugins_dir" do
      it "return valid value" do
        Automatic.user_plugins_dir.should == File.join(APP_ROOT, "spec/user_dir/plugins")
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
      it "return valid value" do
        Automatic.user_dir.should == File.expand_path("~/") + "/.automatic"
      end
    end

    describe "#user_plugins_dir" do
      it "return valid value" do
        Automatic.user_plugins_dir.should == File.expand_path("~/") + "/.automatic/plugins"
      end
    end

    after(:all) do
      ENV["AUTOMATIC_RUBY_ENV"] = "test"
    end
  end

end
