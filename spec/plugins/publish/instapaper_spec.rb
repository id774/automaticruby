require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/instapaper'

describe Automatic::Plugin::PublishInstapaper do
  subject {
    Automatic::Plugin::PublishInstapaper.new(
      {"email" => "email@example.com", "password" => "pswd"},
      AutomaticSpec.generate_pipeline{
        feed { item "http://github.com" }
      }
    )
  }

  it "should post the link in the feed" do
    instapaper = mock("instapaper")
    instapaper.should_receive(:add).with("http://github.com", nil, '')
    subject.instance_variable_set(:@instapaper, instapaper)
    subject.run.should have(1).feed
  end
end

describe Automatic::Plugin::Instapaper do
  describe "#add" do
    subject {
      Automatic::Plugin::Instapaper.new("email@example.com", "pswd")
    }
      url         = "http://www.google.com"
      title       = "automatic test"
      description = "automatic test"

    specify {
      res = stub("res")
      res.should_receive(:code).and_return("201")

      subject.should_receive(:request).and_return(res)
      subject.add(url, title, description)
    }

    specify {
      res = mock("res")
      res.should_receive(:code).twice.and_return("403")

      subject.should_receive(:request).and_return(res)
      subject.add(url, title, description)
    }
  end
end
