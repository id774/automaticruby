require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'notify/ikachan'

describe Automatic::Plugin::NotifyIkachan do
  paramz = {
    "channels" => "#room",
    "url"      => "http://sample.com",
    "port"     => "4979",
    "command"  => "notice",
  }
  subject {
    Automatic::Plugin::NotifyIkachan.new(
      paramz,
      AutomaticSpec.generate_pipeline {
        feed { item "http://github.com", "GitHub" }
      }
    )
  }

  it "should post title and link in the feed" do
    ikachan = double("ikachan")
    ikachan.should_receive(:post).with("http://github.com", "GitHub")
    ikachan.should_receive(:params)
    subject.instance_variable_set(:@ikachan, ikachan)
    subject.run.should have(1).feed
  end
end

describe Automatic::Plugin::Ikachan do
  describe "#post" do
    subject {
      Automatic::Plugin::Ikachan.new.tap {|ikachan|
        ikachan.params = {
          "channels" => "#room",
          "url"      => "http://sample.com",
          "port"     => "4979",
          "command"  => "notice",
        }
      }
    }

    specify {
      link = "http://www.google.com"

      require 'net/http'
      res = double("res")
      res.should_receive(:code).and_return("200")
      http = double("http")
      http.should_receive(:post).with("/join", "channel=#room")
      http.should_receive(:post).with(
        "/notice", "channel=#room&message=#{link}").and_return(res)
      http.should_receive(:start).and_yield(http)
      proxy = Net::HTTP.stub(:new) { http }
      subject.post(link)
    }
  end
end
