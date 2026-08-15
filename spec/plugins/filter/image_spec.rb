# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Image
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Sep 18, 2012
# Updated::     Sep 18, 2012
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/image'

describe Automatic::Plugin::FilterImage do
  context "with feed contain link tag" do
    subject {
      Automatic::Plugin::FilterImage.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://id774.net/images/link_1.jpg"
            item "http://id774.net/images/link_2.jpg"
            item "http://id774.net/images/link_3.JPG"
            item "http://id774.net/images/link_4.png"
            item "http://id774.net/images/link_5.jpeg"
            item "http://id774.net/images/link_6.PNG"
            item "http://id774.net/images/link_7.jpega"
            item "http://id774.net/images/link_8.gif"
            item "http://id774.net/images/link_9.GIF"
            item "http://id774.net/images/link_10.tiff"
            item nil
            item "http://id774.net/images/link_11.TIFF"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        returned = subject.run
        returned[0].items[0].link.
        should == "http://id774.net/images/link_1.jpg"
        returned[0].items[1].link.
        should == "http://id774.net/images/link_2.jpg"
        returned[0].items[2].link.
        should == "http://id774.net/images/link_3.JPG"
        returned[0].items[3].link.
        should == "http://id774.net/images/link_4.png"
        returned[0].items[4].link.
        should == "http://id774.net/images/link_5.jpeg"
        returned[0].items[5].link.
        should == "http://id774.net/images/link_6.PNG"
        returned[0].items[6].link.
        should be_nil
        returned[0].items[7].link.
        should == "http://id774.net/images/link_8.gif"
        returned[0].items[8].link.
        should == "http://id774.net/images/link_9.GIF"
        returned[0].items[9].link.
        should == "http://id774.net/images/link_10.tiff"
        returned[0].items[10].link.
        should be_nil
        returned[0].items[11].link.
        should == "http://id774.net/images/link_11.TIFF"
      }
    end
  end
end

describe Automatic::Plugin::FilterImage do
  # The test is on the path rather than on the whole link, so that an image
  # served with a query string -- which is how most of what serves images now
  # serves them -- is recognised. webp and avif are images too.
  context "with links of the shapes the current web serves" do
    subject {
      Automatic::Plugin::FilterImage.new({},
        AutomaticSpec.generate_pipeline {
          feed {
            item "https://example.com/a.jpg?w=1280&v=2"
            item "https://example.com/b.webp"
            item "https://example.com/c.avif"
            item "https://example.com/d.tif"
            item "https://example.com/e.html?image=f.jpg"
            item "https://example.com/"
          }})}

    specify {
      subject.run[0].items.map(&:link).should == [
        "https://example.com/a.jpg?w=1280&v=2",
        "https://example.com/b.webp",
        "https://example.com/c.avif",
        "https://example.com/d.tif",
        nil,
        nil
      ]
    }
  end
end
