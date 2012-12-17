# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Store::Permalink
# Author::    774 <http://id774.net>
# Updated::   Dec 17, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'store/permalink'
require 'pathname'

describe Automatic::Plugin::StorePermalink do
  it "should store 1 record for the new link" do
    @db_filename = "test_permalink.db"
    db_path = Pathname(AutomaticSpec.db_dir).cleanpath+"#{@db_filename}"
    db_path.delete if db_path.exist?
    Automatic::Plugin::StorePermalink.new({"db" => @db_filename}).run
    instance = Automatic::Plugin::StorePermalink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed { item "http://github.com" }
      })

    lambda {
      instance.run.should have(1).feed
    }.should change(Automatic::Plugin::Permalink, :count).by(1)
  end

  it "should not store record for the existent link" do
    @db_filename = "test_permalink.db"
    db_path = Pathname(AutomaticSpec.db_dir).cleanpath+"#{@db_filename}"
    db_path.delete if db_path.exist?
    Automatic::Plugin::StorePermalink.new({"db" => @db_filename}).run
    instance = Automatic::Plugin::StorePermalink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed { item "http://github.com" }
      }
    )

    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Permalink, :count).by(0)
  end

  it "should be considered the case of the feed link nil" do
    @db_filename = "test_permalink.db"
    db_path = Pathname(AutomaticSpec.db_dir).cleanpath+"#{@db_filename}"
    db_path.delete if db_path.exist?
    Automatic::Plugin::StorePermalink.new({"db" => @db_filename}).run
    instance = Automatic::Plugin::StorePermalink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed {
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_2.jpg"
          item "http://id774.net/images/link_3.JPG"
          item "http://id774.net/images/link_4.png"
          item "http://id774.net/images/link_5.jpeg"
          item "http://id774.net/images/link_6.PNG"
          item nil
          item "http://id774.net/images/link_8.gif"
          item "http://id774.net/images/link_9.GIF"
          item "http://id774.net/images/link_10.tiff"
          item "http://id774.net/images/link_11.TIFF"
        }
      }
    )

    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Permalink, :count).by(0)
  end

  it "should be considered the case of duplicated links" do
    @db_filename = "test_permalink.db"
    db_path = Pathname(AutomaticSpec.db_dir).cleanpath+"#{@db_filename}"
    db_path.delete if db_path.exist?
    Automatic::Plugin::StorePermalink.new({"db" => @db_filename}).run
    instance = Automatic::Plugin::StorePermalink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed {
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_3.JPG"
          item "http://id774.net/images/link_4.png"
          item "http://id774.net/images/link_5.jpeg"
          item "http://id774.net/images/link_6.PNG"
          item nil
          item "http://id774.net/images/link_8.gif"
          item "http://id774.net/images/link_9.GIF"
          item "http://id774.net/images/link_10.tiff"
          item "http://id774.net/images/link_11.TIFF"
        }
      }
    )

    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Permalink, :count).by(0)
  end

  it "No feed should be generated when there is same feed." do
    @db_filename = "test_permalink.db"
    db_path = Pathname(AutomaticSpec.db_dir).cleanpath+"#{@db_filename}"
    db_path.delete if db_path.exist?
    Automatic::Plugin::StorePermalink.new({"db" => @db_filename}).run
    instance = Automatic::Plugin::StorePermalink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed {
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_3.JPG"
          item "http://id774.net/images/link_4.png"
          item "http://id774.net/images/link_5.jpeg"
          item "http://id774.net/images/link_6.PNG"
          item nil
          item "http://id774.net/images/link_8.gif"
          item "http://id774.net/images/link_9.GIF"
          item "http://id774.net/images/link_10.tiff"
          item "http://id774.net/images/link_11.TIFF"
        }
      }
    )

    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Permalink, :count).by(0)
    Automatic::Plugin::StorePermalink.new({"db" => @db_filename}).run
    instance = Automatic::Plugin::StorePermalink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed {
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_3.JPG"
          item "http://id774.net/images/link_4.png"
          item "http://id774.net/images/link_5.jpeg"
          item "http://id774.net/images/link_6.PNG"
          item nil
          item "http://id774.net/images/link_8.gif"
          item "http://id774.net/images/link_9.GIF"
          item "http://id774.net/images/link_10.tiff"
          item "http://id774.net/images/link_11.TIFF"
        }
      }
    )

    instance.run.should have(0).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Permalink, :count).by(0)
  end

  it "Only new feed should be generated when there is new feed." do
    @db_filename = "test_permalink.db"
    db_path = Pathname(AutomaticSpec.db_dir).cleanpath+"#{@db_filename}"
    db_path.delete if db_path.exist?
    Automatic::Plugin::StorePermalink.new({"db" => @db_filename}).run
    instance = Automatic::Plugin::StorePermalink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed {
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_3.JPG"
          item "http://id774.net/images/link_4.png"
          item "http://id774.net/images/link_5.jpeg"
          item "http://id774.net/images/link_6.PNG"
          item nil
          item "http://id774.net/images/link_8.gif"
          item "http://id774.net/images/link_9.GIF"
          item "http://id774.net/images/link_10.tiff"
          item "http://id774.net/images/link_11.TIFF"
        }
      }
    )

    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Permalink, :count).by(0)
    Automatic::Plugin::StorePermalink.new({"db" => @db_filename}).run
    instance = Automatic::Plugin::StorePermalink.new({"db" => @db_filename},
      AutomaticSpec.generate_pipeline {
        feed {
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_1.jpg"
          item "http://id774.net/images/link_3.JPG"
          item "http://id774.net/images/link_4_2.png"
          item "http://id774.net/images/link_5_2.jpeg"
          item "http://id774.net/images/link_6.PNG"
          item nil
          item "http://id774.net/images/link_8.gif"
          item "http://id774.net/images/link_9.GIF"
          item "http://id774.net/images/link_10.tiff"
          item "http://id774.net/images/link_11.TIFF"
        }
      }
    )

    instance.run.should have(1).feed
    lambda {
      instance.run.should have(0).feed
    }.should change(Automatic::Plugin::Permalink, :count).by(0)
  end
end
