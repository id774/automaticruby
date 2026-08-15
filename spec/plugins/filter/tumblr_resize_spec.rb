# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::TumblrResize
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Mar  2, 2012
# Updated::     Jun 14, 2012
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/tumblr_resize'

describe Automatic::Plugin::FilterTumblrResize do
  context "with description with filename of tumblr should be renamed 500 to 1280" do
    subject {
      Automatic::Plugin::FilterTumblrResize.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://27.media.tumblr.com/tumblr_lzrubkfPlt1qb8vzto1_500.png"
            item "http://24.media.tumblr.com/tumblr_m07wttnIdy1qzoj1jo1_400.jpg"
            item "http://28.media.tumblr.com/tumblr_m07wtaxxSa1qzoj1jo1_450.jpg"
            item "http://29.media.tumblr.com/tumblr_m07wrcDBBF1qzoj1jo1_500.jpg"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://27.media.tumblr.com/tumblr_lzrubkfPlt1qb8vzto1_1280.png"
        subject.instance_variable_get(:@pipeline)[0].items[1].link.
        should == "http://24.media.tumblr.com/tumblr_m07wttnIdy1qzoj1jo1_1280.jpg"
        subject.instance_variable_get(:@pipeline)[0].items[2].link.
        should == "http://28.media.tumblr.com/tumblr_m07wtaxxSa1qzoj1jo1_450.jpg"
        subject.instance_variable_get(:@pipeline)[0].items[3].link.
        should == "http://29.media.tumblr.com/tumblr_m07wrcDBBF1qzoj1jo1_1280.jpg"
      }
    end
  end
end

describe Automatic::Plugin::FilterTumblrResize do
  context "with description with filename of tumblr should be renamed 400 to 1280" do
    subject {
      Automatic::Plugin::FilterTumblrResize.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://24.media.tumblr.com/tumblr_m07wttnIdy1qzoj1jo1_400.jpg"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://24.media.tumblr.com/tumblr_m07wttnIdy1qzoj1jo1_1280.jpg"
      }
    end
  end
end

describe Automatic::Plugin::FilterTumblrResize do
  context "with description with filename of tumblr should be renamed 250 to 1280" do
    subject {
      Automatic::Plugin::FilterTumblrResize.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://28.media.tumblr.com/tumblr_m07wtaxxSa1qzoj1jo1_250.jpg"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://28.media.tumblr.com/tumblr_m07wtaxxSa1qzoj1jo1_1280.jpg"
      }
    end
  end
end

describe Automatic::Plugin::FilterTumblrResize do
  context "with description with filename of tumblr should be renamed 100 to 1280" do
    subject {
      Automatic::Plugin::FilterTumblrResize.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://24.media.tumblr.com/tumblr_m07wt8BRWc1qzoj1jo1_100.jpg"
            item "http://25.media.tumblr.com/tumblr_m07wr8RnJ91qzoj1jo1_750.jpg"
            item "http://29.media.tumblr.com/tumblr_m07wrcDBBF1qzoj1jo1_75sq.jpg"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://24.media.tumblr.com/tumblr_m07wt8BRWc1qzoj1jo1_1280.jpg"
        subject.instance_variable_get(:@pipeline)[0].items[1].link.
        should == "http://25.media.tumblr.com/tumblr_m07wr8RnJ91qzoj1jo1_750.jpg"
        subject.instance_variable_get(:@pipeline)[0].items[2].link.
        should == "http://29.media.tumblr.com/tumblr_m07wrcDBBF1qzoj1jo1_1280.jpg"
      }
    end
  end
end

# Tumblr has served images under two URL schemes. The size suffix above is the
# older one, which images uploaded before 2019 still carry; everything since
# carries the size as a path segment, and the plugin rewrites that as well.
describe Automatic::Plugin::FilterTumblrResize do
  context "with the current media.tumblr.com URL scheme" do
    subject {
      Automatic::Plugin::FilterTumblrResize.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "https://64.media.tumblr.com/aaa/bbb-1f/s540x810/ccc.jpg"
            item "https://66.media.tumblr.com/aaa/bbb-1f/s75x75_c1/ccc.jpg"
            item "https://64.media.tumblr.com/aaa/bbb-1f/s1280x1920/ccc.jpg"
            item "https://example.com/not/a/tumblr/image.jpg"
          }})}

    specify {
      returned = subject.run
      returned[0].items[0].link.
        should == "https://64.media.tumblr.com/aaa/bbb-1f/s1280x1920/ccc.jpg"
      returned[0].items[1].link.
        should == "https://66.media.tumblr.com/aaa/bbb-1f/s75x75_c1/ccc.jpg"
      returned[0].items[2].link.
        should == "https://64.media.tumblr.com/aaa/bbb-1f/s1280x1920/ccc.jpg"
      returned[0].items[3].link.
        should == "https://example.com/not/a/tumblr/image.jpg"
    }
  end
end
