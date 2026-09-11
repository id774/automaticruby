# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Kimi
# Author:       id774 (More info: https://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Sep 11, 2026
# Updated::     Sep 11, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/kimi'
require 'json'
require 'net/http'

# FilterKimi needs a Kimi API token; doc/PLUGINS.md section 6.3 classifies it
# as Supported (external). Everything up to the request is verified here --
# what is posted where, with which authentication, and what each answer means
# -- and no example reaches the service. Only Kimi is exercised: the other AI
# filters have their own specs, and none of them stands in for another.
module KimiSpec
  module_function

  # A real response object, because the plugin decides what to do from the
  # class Net::HTTP would have given it.
  def response(klass, code, body)
    response = klass.new('1.1', code, 'Status')
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    response
  end

  # A finished answer. `reasoning` is folded into the same message when given,
  # exactly the way Kimi may send `reasoning_content` alongside `content` --
  # so a spec can prove it never leaks into the description.
  def answered(text, reasoning: nil, finish_reason: 'stop')
    message = { 'role' => 'assistant', 'content' => text }
    message['reasoning_content'] = reasoning unless reasoning.nil?

    response(Net::HTTPOK, '200', JSON.generate(
      'object' => 'chat.completion',
      'choices' => [
        { 'index' => 0, 'message' => message, 'finish_reason' => finish_reason }
      ]
    ))
  end

  def refused(klass, code, message)
    response(klass, code, JSON.generate('error' => { 'message' => message }))
  end
end

describe Automatic::Plugin::FilterKimi do
  let(:settings) {
    { 'token' => 'test-token', 'model' => 'kimi-k3', 'prompt' => 'Summarize this.',
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
    Automatic::Plugin::FilterKimi.new(config, pipeline).run
  end

  describe 'the request it builds' do
    before {
      serve(KimiSpec.answered('a summary'))
      run(settings, one_item)
    }

    it "posts to Kimi's own endpoint, over verified TLS" do
      connections[0][0].should == 'api.moonshot.ai'
      connections[0][1].should == 443
      connections[0].last[:use_ssl].should == true
      connections[0].last[:verify_mode].should == OpenSSL::SSL::VERIFY_PEER
      posted[0].path.should == '/v1/chat/completions'
    end

    it 'sends the token as a bearer token' do
      posted[0]['authorization'].should == 'Bearer test-token'
      posted[0]['content-type'].should == 'application/json'
    end

    it 'sends only the model, the prompt as the system turn and the description as the user turn' do
      JSON.parse(posted[0].body).should == {
        'model' => 'kimi-k3',
        'messages' => [
          { 'role' => 'system', 'content' => 'Summarize this.' },
          { 'role' => 'user', 'content' => 'the body of A' }
        ]
      }
    end
  end

  describe 'what it does to the pipeline' do
    it 'replaces the description with the answer and leaves the rest alone' do
      serve(KimiSpec.answered('a summary'))
      returned = run(settings, one_item)

      returned.should have(1).feed
      returned[0].items.should have(1).item
      returned[0].items[0].description.should == 'a summary'
      returned[0].items[0].title.should == 'A'
      returned[0].items[0].link.should == 'https://example.com/a'
    end

    it 'asks once for each item' do
      serve(KimiSpec.answered('first summary'), KimiSpec.answered('second summary'))
      returned = run(settings, AutomaticSpec.generate_pipeline {
        feed {
          item 'https://example.com/a', 'A', 'the body of A'
          item 'https://example.com/b', 'B', 'the body of B'
        }
      })

      posted.should have(2).requests
      JSON.parse(posted[0].body)['messages'][1]['content'].should == 'the body of A'
      JSON.parse(posted[1].body)['messages'][1]['content'].should == 'the body of B'
      returned[0].items.map(&:description).should == ['first summary', 'second summary']
    end

    it 'ignores a feed that is nil' do
      serve(KimiSpec.answered('a summary'))
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
  end

  describe 'when the request fails' do
    it 'retries a server error and carries on' do
      serve(KimiSpec.refused(Net::HTTPInternalServerError, '500', 'server error'),
            KimiSpec.answered('a summary'))
      returned = run(settings, one_item)

      posted.should have(2).requests
      returned[0].items[0].description.should == 'a summary'
    end

    it 'retries a rate limit' do
      serve(KimiSpec.refused(Net::HTTPTooManyRequests, '429', 'too many requests'),
            KimiSpec.answered('a summary'))
      run(settings, one_item)[0].items[0].description.should == 'a summary'
      posted.should have(2).requests
    end

    it 'does not retry a network failure past the configured count' do
      Net::HTTP.stub(:start) { raise SocketError, 'getaddrinfo failed' }
      lambda { run(settings, one_item) }.
        should raise_error(Automatic::Plugin::FilterKimi::Error, /gave up/)
    end

    it 'gives up after the configured number of retries' do
      serve(KimiSpec.refused(Net::HTTPInternalServerError, '500', 'server error'),
            KimiSpec.refused(Net::HTTPInternalServerError, '500', 'server error'))
      lambda { run(settings, one_item) }.
        should raise_error(Automatic::Plugin::FilterKimi::Error, /gave up/)
      posted.should have(2).requests
    end

    it 'does not retry a rejected request' do
      serve(KimiSpec.refused(Net::HTTPUnauthorized, '401', 'invalid token'))
      lambda { run(settings, one_item) }.
        should raise_error(Automatic::Plugin::FilterKimi::Error, /401/)
      posted.should have(1).request
    end

    it 'does not empty the description when the service fails' do
      serve(KimiSpec.refused(Net::HTTPUnauthorized, '401', 'invalid token'))
      pipeline = one_item
      lambda { run(settings, pipeline) }.should raise_error(StandardError)
      pipeline[0].items[0].description.should == 'the body of A'
    end
  end

  describe 'when the answer cannot be read' do
    it 'raises on a body that is not JSON' do
      serve(KimiSpec.response(Net::HTTPOK, '200', 'not json at all'))
      lambda { run(settings, one_item) }.
        should raise_error(Automatic::Plugin::FilterKimi::Error, /not JSON/)
      posted.should have(1).request
    end

    it 'raises on a body without the choice it expects' do
      serve(KimiSpec.response(Net::HTTPOK, '200', JSON.generate('id' => 'cmpl_1')))
      lambda { run(settings, one_item) }.
        should raise_error(Automatic::Plugin::FilterKimi::Error, /without a choice/)
    end

    it 'raises rather than writing an empty description' do
      serve(KimiSpec.answered(''))
      pipeline = one_item
      lambda { run(settings, pipeline) }.
        should raise_error(Automatic::Plugin::FilterKimi::Error, /no content/)
      pipeline[0].items[0].description.should == 'the body of A'
    end

    it 'raises when the model has not finished, and does not empty the description' do
      serve(KimiSpec.answered('a partial answer', finish_reason: 'length'))
      pipeline = one_item
      lambda { run(settings, pipeline) }.
        should raise_error(Automatic::Plugin::FilterKimi::Error, /did not finish/)
      pipeline[0].items[0].description.should == 'the body of A'
    end

    it 'never lets reasoning_content reach the description' do
      serve(KimiSpec.answered('a summary', reasoning: 'because the article said so'))
      returned = run(settings, one_item)

      returned[0].items[0].description.should == 'a summary'
      returned[0].items[0].description.should_not include('because the article said so')
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

      serve(KimiSpec.refused(Net::HTTPUnauthorized, '401', 'invalid token'))
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
      serve(KimiSpec.answered('a summary'))
      returned = run(settings, one_item)
      returned[0].items[0].description.should_not include('test-token')
    end
  end
end
