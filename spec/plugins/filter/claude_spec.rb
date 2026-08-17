# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Claude
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 17, 2026
# Updated::     Aug 17, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/claude'
require 'json'
require 'net/http'

# FilterClaude needs an Anthropic API token; doc/PLUGINS.md section 6.3
# classifies it as Supported (external). Everything up to the request is
# verified here -- what is posted where, with which authentication, and what
# each answer means -- and no example reaches the service. Only Anthropic is
# exercised: the other AI filters have their own specs, and none of them stands
# in for another.
module ClaudeSpec
  module_function

  # A real response object, because the plugin decides what to do from the
  # class Net::HTTP would have given it.
  def response(klass, code, body)
    response = klass.new('1.1', code, 'Status')
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    response
  end

  def answered(text)
    response(Net::HTTPOK, '200', JSON.generate(
      'type' => 'message',
      'role' => 'assistant',
      'content' => [{ 'type' => 'text', 'text' => text }],
      'stop_reason' => 'end_turn'
    ))
  end

  def refused(klass, code, message)
    response(klass, code, JSON.generate(
      'type' => 'error', 'error' => { 'type' => 'invalid_request_error', 'message' => message }
    ))
  end
end

describe Automatic::Plugin::FilterClaude do
  let(:settings) {
    { 'token' => 'test-token', 'model' => 'claude-test', 'prompt' => 'Summarize this.',
      'retry' => 1, 'interval' => 0 }
  }

  let(:posted) { [] }
  let(:connections) { [] }

  def one_item
    AutomaticSpec.generate_pipeline {
      feed { item 'https://example.com/a', 'A', 'the body of A' }
    }
  end

  # Stands in for the network: records the connection and the request, answers
  # with what the example queued, and opens nothing. The default suite reaches
  # no network (doc/POLICY.md Invariant 6).
  def serve(*responses)
    requests = posted
    opened = connections
    Net::HTTP.stub(:start) { |*args, &block|
      opened << args
      http = double('http')
      http.stub(:request) { |request|
        requests << request
        responses.shift
      }
      block.call(http)
    }
  end

  def run(config, pipeline)
    Automatic::Plugin::FilterClaude.new(config, pipeline).run
  end

  describe 'the request it builds' do
    before {
      serve(ClaudeSpec.answered('a summary'))
      run(settings, one_item)
    }

    it 'posts to the Messages API over TLS, with the certificate verified' do
      connections[0][0].should == 'api.anthropic.com'
      connections[0][1].should == 443
      connections[0].last[:use_ssl].should == true
      connections[0].last[:verify_mode].should == OpenSSL::SSL::VERIFY_PEER
      posted[0].path.should == '/v1/messages'
    end

    it 'sends the token in the header this API authenticates with' do
      posted[0]['x-api-key'].should == 'test-token'
      posted[0]['authorization'].should be_nil
      posted[0]['content-type'].should == 'application/json'
    end

    it 'sends the API version this API requires' do
      posted[0]['anthropic-version'].should == Automatic::Plugin::FilterClaude::API_VERSION
    end

    it 'sends the model, the prompt as the system turn and the description as the user turn' do
      JSON.parse(posted[0].body).should == {
        'model' => 'claude-test',
        'max_tokens' => Automatic::Plugin::FilterClaude::DEFAULT_MAX_TOKENS,
        'system' => 'Summarize this.',
        'messages' => [{ 'role' => 'user', 'content' => 'the body of A' }]
      }
    end
  end

  describe 'max_tokens' do
    it 'takes the length the Recipe asks for' do
      serve(ClaudeSpec.answered('a summary'))
      run(settings.merge('max_tokens' => 256), one_item)
      JSON.parse(posted[0].body)['max_tokens'].should == 256
    end

    it 'refuses a length that is not one' do
      lambda { run(settings.merge('max_tokens' => 0), one_item) }.
        should raise_error(ArgumentError, /max_tokens/)
    end
  end

  describe 'what it does to the pipeline' do
    it 'replaces the description with the answer and leaves the rest alone' do
      serve(ClaudeSpec.answered('a summary'))
      returned = run(settings, one_item)

      returned.should have(1).feed
      returned[0].items.should have(1).item
      returned[0].items[0].description.should == 'a summary'
      returned[0].items[0].title.should == 'A'
      returned[0].items[0].link.should == 'https://example.com/a'
    end

    it 'asks once for each item' do
      serve(ClaudeSpec.answered('first summary'), ClaudeSpec.answered('second summary'))
      returned = run(settings, AutomaticSpec.generate_pipeline {
        feed {
          item 'https://example.com/a', 'A', 'the body of A'
          item 'https://example.com/b', 'B', 'the body of B'
        }
      })

      posted.should have(2).requests
      JSON.parse(posted[0].body)['messages'][0]['content'].should == 'the body of A'
      JSON.parse(posted[1].body)['messages'][0]['content'].should == 'the body of B'
      returned[0].items.map(&:description).should == ['first summary', 'second summary']
    end

    it 'ignores a feed that is nil' do
      serve(ClaudeSpec.answered('a summary'))
      run(settings, [nil] + one_item).should have(2).feeds
      posted.should have(1).request
    end

    it 'sends nothing for an item with no description, and empties none' do
      serve
      returned = run(settings, AutomaticSpec.generate_pipeline {
        feed {
          item 'https://example.com/a', 'A', ''
          item 'https://example.com/b', 'B', '   '
        }
      })

      posted.should be_empty
      returned[0].items.map(&:description).should == ['', '   ']
    end

    it 'reads the text out of an answer that carries blocks of other kinds' do
      serve(ClaudeSpec.response(Net::HTTPOK, '200', JSON.generate(
        'content' => [
          { 'type' => 'thinking', 'thinking' => '' },
          { 'type' => 'text', 'text' => 'a summary' }
        ]
      )))
      run(settings, one_item)[0].items[0].description.should == 'a summary'
    end
  end

  describe 'when the request fails' do
    it 'retries a server error and carries on' do
      serve(ClaudeSpec.refused(Net::HTTPInternalServerError, '500', 'server error'),
            ClaudeSpec.answered('a summary'))
      returned = run(settings, one_item)

      posted.should have(2).requests
      returned[0].items[0].description.should == 'a summary'
    end

    it 'retries a rate limit' do
      serve(ClaudeSpec.refused(Net::HTTPTooManyRequests, '429', 'rate limited'),
            ClaudeSpec.answered('a summary'))
      run(settings, one_item)[0].items[0].description.should == 'a summary'
      posted.should have(2).requests
    end

    it 'gives up after the configured number of retries' do
      serve(ClaudeSpec.refused(Net::HTTPInternalServerError, '500', 'server error'),
            ClaudeSpec.refused(Net::HTTPInternalServerError, '500', 'server error'))
      lambda { run(settings, one_item) }.
        should raise_error(Automatic::Plugin::FilterClaude::Error, /gave up/)
      posted.should have(2).requests
    end

    it 'does not retry a rejected request' do
      serve(ClaudeSpec.refused(Net::HTTPUnauthorized, '401', 'invalid x-api-key'))
      lambda { run(settings, one_item) }.
        should raise_error(Automatic::Plugin::FilterClaude::Error, /401/)
      posted.should have(1).request
    end

    it 'does not empty the description when the service fails' do
      serve(ClaudeSpec.refused(Net::HTTPUnauthorized, '401', 'invalid x-api-key'))
      pipeline = one_item
      lambda { run(settings, pipeline) }.should raise_error(StandardError)
      pipeline[0].items[0].description.should == 'the body of A'
    end
  end

  describe 'when the answer cannot be read' do
    it 'raises on a body that is not JSON' do
      serve(ClaudeSpec.response(Net::HTTPOK, '200', 'not json at all'))
      lambda { run(settings, one_item) }.
        should raise_error(Automatic::Plugin::FilterClaude::Error, /not JSON/)
      posted.should have(1).request
    end

    it 'raises on a body without the content it expects' do
      serve(ClaudeSpec.response(Net::HTTPOK, '200', JSON.generate('id' => 'msg_1')))
      lambda { run(settings, one_item) }.
        should raise_error(Automatic::Plugin::FilterClaude::Error, /content array/)
    end

    it 'raises rather than writing an empty description' do
      serve(ClaudeSpec.response(Net::HTTPOK, '200', JSON.generate('content' => [])))
      pipeline = one_item
      lambda { run(settings, pipeline) }.
        should raise_error(Automatic::Plugin::FilterClaude::Error, /no text content/)
      pipeline[0].items[0].description.should == 'the body of A'
    end
  end

  describe 'the settings it requires' do
    it 'refuses a Recipe with no token' do
      lambda { run(settings.merge('token' => nil), one_item) }.
        should raise_error(ArgumentError, /token/)
    end

    it 'refuses a Recipe with no model' do
      lambda { run(settings.merge('model' => ''), one_item) }.
        should raise_error(ArgumentError, /model/)
    end

    it 'refuses a Recipe with no prompt' do
      lambda { run(settings.merge('prompt' => nil), one_item) }.
        should raise_error(ArgumentError, /prompt/)
    end

    it 'asks nothing before it has what it needs' do
      serve
      lambda { run(settings.merge('prompt' => nil), one_item) }.should raise_error(ArgumentError)
      posted.should be_empty
    end
  end

  describe 'the credential' do
    # doc/PLUGINS.md section 3.7: never logged, never in an exception message,
    # never written into an item.
    it 'reaches neither the log nor the error, on the path that fails' do
      messages = []
      logger = double('logger')
      %i[info warn error].each { |level| logger.stub(level) { |message| messages << message.to_s } }
      original = Automatic::Log.logger

      serve(ClaudeSpec.refused(Net::HTTPUnauthorized, '401', 'invalid x-api-key'))
      begin
        Automatic::Log.logger = logger
        Automatic::Log.level('info')
        lambda { run(settings, one_item) }.should raise_error(StandardError) { |error|
          error.message.should_not include('test-token')
        }
      ensure
        Automatic::Log.level('none')
        Automatic::Log.logger = original
      end

      messages.should_not be_empty
      messages.each { |message| message.should_not include('test-token') }
    end

    it 'writes nothing of itself into the item' do
      serve(ClaudeSpec.answered('a summary'))
      returned = run(settings, one_item)
      returned[0].items[0].description.should_not include('test-token')
    end
  end
end
