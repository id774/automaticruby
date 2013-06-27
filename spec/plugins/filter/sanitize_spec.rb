# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Sanitize
# Author::    774 <http://id774.net>
# Created::   Jun 20, 2013
# Updated::   Jun 20, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/sanitize'

describe Automatic::Plugin::FilterSanitize do
  context "It should be sanitized" do
    subject {
      Automatic::Plugin::FilterSanitize.new(
        {},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://testsite.org", "hoge",
            "<a>fuga</a>",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@return_feeds)[0].items.
          count.should == 1
        subject.instance_variable_get(:@return_feeds)[0].items[0].description.
          should == 'fuga'
      }
    end
  end

  context "It should not be sanitized in basic mode" do
    subject {
      Automatic::Plugin::FilterSanitize.new(
        {
          'mode' => "basic"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://testsite.org", "hoge",
            "<a>fuga</a>",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@return_feeds)[0].items.
          count.should == 1
        subject.instance_variable_get(:@return_feeds)[0].items[0].description.
          should == '<a rel="nofollow">fuga</a>'
      }
    end
  end

  context "It should not be sanitized in restricted mode" do
    subject {
      Automatic::Plugin::FilterSanitize.new(
        {
          'mode' => "restricted"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://testsite.org", "hoge",
            "<a>fuga</a>",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@return_feeds)[0].items.
          count.should == 1
        subject.instance_variable_get(:@return_feeds)[0].items[0].description.
          should == 'fuga'
      }
    end
  end

  context "It should not be sanitized in relaxed mode" do
    subject {
      Automatic::Plugin::FilterSanitize.new(
        {
          'mode' => "relaxed"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://testsite.org", "hoge",
            "<a>fuga</a>",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@return_feeds)[0].items.
          count.should == 1
        subject.instance_variable_get(:@return_feeds)[0].items[0].description.
          should == '<a>fuga</a>'
      }
    end
  end

  context "It should be sanitized" do
    subject {
      Automatic::Plugin::FilterSanitize.new(
        {},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://testsite.org", "hoge"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@return_feeds)[0].items.
          count.should == 1
        subject.instance_variable_get(:@return_feeds)[0].items[0].description.
          should == ''
      }
    end
  end

end
