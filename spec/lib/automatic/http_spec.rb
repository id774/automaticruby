# -*- coding: utf-8 -*-
# Name::        Automatic::Http
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 15, 2026
# Updated::     Aug 21, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

describe Automatic::Http do
  describe '.uri' do
    it 'parses an ordinary URL' do
      Automatic::Http.uri('https://example.com/feed').to_s.should == 'https://example.com/feed'
    end

    it 'normalizes the host and an empty path' do
      Automatic::Http.uri('http://EXAMPLE.com').to_s.should == 'http://example.com/'
    end

    # A feed URL carrying a Japanese query term, or a link with a space in it,
    # is escaped and parsed again rather than ending the run.
    it 'escapes a string carrying characters a URI may not' do
      Automatic::Http.uri('http://example.com/a b').to_s.should == 'http://example.com/a%20b'
    end

    it 'trims surrounding whitespace' do
      Automatic::Http.uri("  https://example.com/feed\n").to_s.
        should == 'https://example.com/feed'
    end

    # A link arrives from a feed, which is to say from outside. Only HTTP and
    # HTTPS are fetched, so that a plugin cannot be talked into reading a local
    # file or opening an FTP session.
    %w[file:///etc/passwd ftp://example.com/x gopher://example.com/].each do |url|
      it "refuses #{url}" do
        lambda { Automatic::Http.uri(url) }.
          should raise_error(ArgumentError, /not an HTTP or HTTPS URL/)
      end
    end

    it 'refuses an empty URL' do
      lambda { Automatic::Http.uri('   ') }.should raise_error(ArgumentError, /no URL/)
    end

    it 'refuses a string that is not a URL at all' do
      lambda { Automatic::Http.uri('invalid_url') }.should raise_error(ArgumentError)
    end

    %w[http:example.com https:/feed].each do |url|
      it "refuses #{url} without a host" do
        lambda { Automatic::Http.uri(url) }.
          should raise_error(ArgumentError, /has no host/)
      end
    end
  end

  describe '.fetchable?' do
    it 'answers for a URL this framework will fetch' do
      Automatic::Http.fetchable?('https://example.com/').should be true
    end

    it 'answers false rather than raising for one it will not' do
      Automatic::Http.fetchable?('file:///etc/passwd').should be false
      Automatic::Http.fetchable?('https:/feed').should be false
      Automatic::Http.fetchable?(nil).should be false
    end
  end

  describe '.read' do
    it 'opens the URI with a timeout, a redirect limit and this project as the agent' do
      uri = double('uri')
      Automatic::Http.stub(:uri).and_return(uri)
      uri.should_receive(:open) { |options, &block|
        options['User-Agent'].should include('Automatic Ruby')
        options[:open_timeout].should == Automatic::Http::OPEN_TIMEOUT
        options[:read_timeout].should == Automatic::Http::READ_TIMEOUT
        options[:max_redirects].should == Automatic::Http::REDIRECT_LIMIT
        block.call(StringIO.new('a body'))
      }

      Automatic::Http.read('https://example.com/').should == 'a body'
    end
  end
end
