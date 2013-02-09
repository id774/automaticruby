require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'subscription/google_reader_star'

describe Automatic::Plugin::SubscriptionGoogleReaderStar do
  context "with empty feeds" do
    subject {
      Automatic::Plugin::SubscriptionGoogleReaderStar.new(
        { 'feeds' => [] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with feeds whose invalid URL" do
    subject {
      Automatic::Plugin::SubscriptionGoogleReaderStar.new(
        { 'feeds' => ["invalid_url"] }
      )
    }

    its(:run) { should be_empty }
  end

  context "with feeds whose valid URL" do
    subject {
      Automatic::Plugin::SubscriptionGoogleReaderStar.new(
        { 'feeds' => [
            "http://www.google.com/reader/public/atom/user%2F00482198897189159802%2Fstate%2Fcom.google%2Fstarred"]
        }
      )
    }

    its(:run) { should have(1).feed }
  end
end
