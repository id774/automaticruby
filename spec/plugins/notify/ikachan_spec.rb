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
    ikachan = mock("ikachan")
    ikachan.should_receive(:post).with("http://github.com", "GitHub")
    ikachan.should_receive(:params)
    subject.instance_variable_set(:@ikachan, ikachan)
    subject.run.should have(1).feed
  end
end
