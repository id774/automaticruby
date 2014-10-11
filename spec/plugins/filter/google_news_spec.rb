# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::GoogleNews
# Author::    774 <http://id774.net>
# Created::   Oct 12, 2014
# Updated::   Oct 12, 2014
# Copyright:: Copyright (c) 2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/google_news'

describe Automatic::Plugin::FilterGoogleNews do

  context "It should be not rewrite link other urls" do

    subject {
      Automatic::Plugin::FilterGoogleNews.new(
        {},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://test1.id774.net",
            "dummy title",
            "aaa bbb ccc http://test2.id774.net ddd eee",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://test1.id774.net"
      }
    end
  end

  context "It should be rewrite link for google news urls" do

    subject {
      Automatic::Plugin::FilterGoogleNews.new(
        {},
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://news.google.com/news/url?sa=t&fd=R&ct2=us&usg=AFQjCNGhIFo1illQ6jFyVGPZtfkttFaJYQ&clid=c3a7d30bb8a4878e06b80cf16b898331&cid=52779138313507&ei=Pts3VLDAD4X7kgWO9oGIBg&url=http://www.yomiuri.co.jp/world/20141010-OYT1T50090.html",
            "dummy title",
            "aaa bbb ccc http://test2.id774.net ddd eee",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }
        }
      )
    }

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.run
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://www.yomiuri.co.jp/world/20141010-OYT1T50090.html"
      }
    end
  end

end
