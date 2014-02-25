# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::HatenaBookmark
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 25, 2014
# Copyright:: Copyright (c) 2012-2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/hatena_bookmark'

describe Automatic::Plugin::PublishHatenaBookmark do
  subject {
    Automatic::Plugin::PublishHatenaBookmark.new(
      {"username" => "user", "password" => "pswd"},
      AutomaticSpec.generate_pipeline{
        feed { item "http://github.com" }
      }
    )
  }

  it "should post the link with prefix 'http' in the feed" do
    hb = double("hb")
    hb.should_receive(:post).with("http://github.com", nil)
    subject.instance_variable_set(:@hb, hb)
    subject.run.should have(1).feed
  end
end

describe Automatic::Plugin::PublishHatenaBookmark do
  subject {
    Automatic::Plugin::PublishHatenaBookmark.new(
      {"username" => "user", "password" => "pswd"},
      AutomaticSpec.generate_pipeline{
        feed { item "//github.com" }
      }
    )
  }

  it "should post the link with prefix '//...' in the feed" do
    hb = double("hb")
    hb.should_receive(:post).with("http://github.com", nil)
    subject.instance_variable_set(:@hb, hb)
    subject.run.should have(1).feed
  end
end

describe Automatic::Plugin::PublishHatenaBookmark do
  subject {
    Automatic::Plugin::PublishHatenaBookmark.new(
      {"username" => "user", "password" => "pswd"},
      AutomaticSpec.generate_pipeline{
        feed { item "https://github.com" }
      }
    )
  }

  it "should post the link with prefix 'https' in the feed" do
    hb = double("hb")
    hb.should_receive(:post).with("https://github.com", nil)
    subject.instance_variable_set(:@hb, hb)
    subject.run.should have(1).feed
  end
end

describe Automatic::Plugin::PublishHatenaBookmark do
  subject {
    Automatic::Plugin::PublishHatenaBookmark.new(
      {"username" => "user", "password" => "pswd"},
      AutomaticSpec.generate_pipeline{
        feed { item "github.com" }
      }
    )
  }

  it "should post the link with others in the feed" do
    hb = double("hb")
    hb.should_receive(:post).with("http://github.com", nil)
    subject.instance_variable_set(:@hb, hb)
    subject.run.should have(1).feed
  end
end

describe Automatic::Plugin::HatenaBookmark do
  describe "#wsse" do
    subject {
      Automatic::Plugin::HatenaBookmark.new.wsse("anonymous", "pswd")
    }

    it { should be_has_key('X-WSSE') }

    specify {
      subject['X-WSSE'].should match(
        /^UsernameToken\sUsername="anonymous",\sPasswordDigest=".+", Nonce=".+", Created="\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z"/)
    }
  end

  describe "#post" do
    subject {
      Automatic::Plugin::HatenaBookmark.new
    }

    specify {
      url = "http://www.google.com"
      comment = "Can we trust them ?"

      require 'net/http'
      res = stub("res")
      res.should_receive(:code).and_return("201")
      http = double("http")
      http.should_receive(:post).with("/atom/post", subject.toXml(url, comment),
        subject.wsse("", "")).and_return(res)
      http.should_receive(:start).and_yield(http)
      proxy = Net::HTTP.stub(:new) { http }
      subject.post(url, comment)
    }

    specify {
      url = "http://www.google.com"
      comment = "Can we trust them ?"

      require 'net/http'
      res = stub("res")
      res.should_receive(:code).twice.and_return("400")
      http = double("http")
      http.should_receive(:post).with("/atom/post", subject.toXml(url, comment),
        subject.wsse("", "")).and_return(res)
      http.should_receive(:start).and_yield(http)
      proxy = Net::HTTP.stub(:new) { http }
      subject.post(url, comment)
    }
  end
end
