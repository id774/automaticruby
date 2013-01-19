# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Ignore
# Author::    774 <http://id774.net>
# Updated::   Jan 19, 2013
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/ignore'

describe Automatic::Plugin::FilterIgnore do
  context "with exclusion by links" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'link' => ["comment"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(2).feeds }
    end
  end

  context "with exclusion by links" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'link' => ["comment"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com/comment" }
        })
    }

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end

  context "with exclusion by links" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'link' => ["hoge"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(2).feeds }
    end
  end

  context "with exclusion by links" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'link' => ["hoge"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com/hoge" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end

  context "with exclusion by links" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'link' => ["github"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end

  context "with exclusion by links" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'link' => [""],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(0).feeds }
    end
  end

  context "with exclusion by description" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'description' => ["comment"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(2).feeds }
    end
  end

  context "with exclusion by description" do
    subject {
      Automatic::Plugin::FilterIgnore.new({
        'description' => [""],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(0).feeds }
    end
  end
end
