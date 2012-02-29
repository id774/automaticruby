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
    hb = mock("@hb")
    hb.should_receive(:post).with(:link => "http://github.com")
    subject.instance_variable_set(:@hb, hb)
    subject.run.should have(1).feed
  end
end
