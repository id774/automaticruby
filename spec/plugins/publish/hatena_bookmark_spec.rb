require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/hatena_bookmark'

describe Automatic::Plugin::PublishHatenaBookmark do
  subject {
    Automatic::Plugin::PublishHatenaBookmark.new(
      {"username" => "user", "password" => "pswd"},
      AutomaticSpec.generate_pipeline{
        feed { item "http://github.com" }
      })
  }

  it "should post the link in the feed" do
    hb = mock("hb")
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
      http = mock("http")
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
      http = mock("http")
      http.should_receive(:post).with("/atom/post", subject.toXml(url, comment),
        subject.wsse("", "")).and_return(res)
      http.should_receive(:start).and_yield(http)
      proxy = Net::HTTP.stub(:new) { http }
      subject.post(url, comment)
    }
  end
end
