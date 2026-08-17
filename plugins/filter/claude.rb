# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Claude
# Description:: Replace each item's description with what the Anthropic Claude API answers.
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 17, 2026
# Updated::     Aug 17, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# One transformation: the item's description goes to the Anthropic Messages API
# under the Recipe's prompt, and the answer becomes the item's description.
# What that transformation is -- a summary, a translation, an extraction, a
# classification -- is the prompt's business, not this plugin's.
#
# This plugin knows Anthropic and nothing else. Its authentication is an
# `x-api-key` header rather than a bearer token, it requires an API version
# header and a `max_tokens`, and its answer is a list of content blocks. None
# of that is bent into another service's shape, and no other service's request
# is built here.
#
# @see https://docs.anthropic.com/en/api/messages

module Automatic::Plugin
  class FilterClaude
    require 'json'
    require 'net/http'
    require 'openssl'
    require 'uri'

    ENDPOINT = URI('https://api.anthropic.com/v1/messages')

    # The API version header the Messages API requires on every request. It is
    # the version of the HTTP interface, not of a model, which is why it is a
    # constant here and the model is a setting.
    API_VERSION = '2023-06-01'.freeze

    # `max_tokens` is required by this API and by no other one this repository
    # speaks to, so it is a setting of this plugin alone. The default is a
    # length a digest or a translation fits in; a Recipe that wants a longer
    # answer says so.
    DEFAULT_MAX_TOKENS = 4096

    OPEN_TIMEOUT = 10

    # Generous, and bounded. A model given several articles thinks for a while;
    # an unattended run that waits forever is the failure this exists against.
    READ_TIMEOUT = 300

    # A failure that another attempt will not get past: a setting that is
    # wrong, a request the service refuses, an answer this plugin cannot read.
    class Error < StandardError; end

    # A failure that another attempt may get past: the network, a rate limit, a
    # server error.
    class TemporaryError < StandardError; end

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
    end

    # Replaces each item's description with the answer. Nothing else about an
    # item is touched, and the feeds and their items arrive and leave in the
    # same order and number.
    def run
      validate_settings

      @pipeline.each { |feeds|
        next if feeds.nil?

        feeds.items.each { |item| transform(item) }
      }
      @pipeline
    end

    private

    # Checked before the first request, because a Recipe this plugin cannot
    # carry out is the operator's mistake and will be the same mistake on every
    # item. The token is never named in a message.
    def validate_settings
      raise ArgumentError, 'FilterClaude needs a token' if token.empty?
      raise ArgumentError, 'FilterClaude needs a model' if model.empty?
      raise ArgumentError, 'FilterClaude needs a prompt' if prompt.empty?
      raise ArgumentError, 'FilterClaude needs a positive max_tokens' unless max_tokens.positive?
    end

    def token
      @config['token'].to_s
    end

    def model
      @config['model'].to_s.strip
    end

    def prompt
      @config['prompt'].to_s.strip
    end

    def max_tokens
      given = @config['max_tokens']
      given.nil? ? DEFAULT_MAX_TOKENS : given.to_i
    end

    def transform(item)
      text = item.description.to_s
      if text.strip.empty?
        Automatic::Log.puts('warn', "FilterClaude: nothing to send for #{item.link}")
        return
      end

      Automatic::Log.puts('info', "FilterClaude: asking #{model} about #{item.link}")
      item.description = answer(text)
    end

    # The retry shape of doc/PLUGINS.md section 3.6, applied only to what
    # retrying can help. A missing setting, a refused request or an answer in a
    # shape this plugin cannot read is raised at once: trying again would fail
    # the same way, more slowly.
    def answer(text)
      retries   = 0
      retry_max = @config['retry'].to_i
      begin
        message(text)
      rescue TemporaryError => e
        retries += 1
        Automatic::Log.puts('error', "ErrorCount: #{retries}, FilterClaude: #{e.message}")
        if retries <= retry_max
          sleep(@config['interval'].to_i)
          retry
        end
        raise Error, "FilterClaude gave up after #{retries} attempts: #{e.message}"
      end
    end

    def message(text)
      # The prompt is the system instruction and the description is the user
      # turn it is applied to. They are separate fields, so that what an
      # article says is never read as an instruction to this plugin or to the
      # model.
      body = {
        'model' => model,
        'max_tokens' => max_tokens,
        'system' => prompt,
        'messages' => [{ 'role' => 'user', 'content' => text }]
      }
      content(post(JSON.generate(body)))
    end

    def post(body)
      request = Net::HTTP::Post.new(ENDPOINT)
      request['x-api-key']         = token
      request['anthropic-version'] = API_VERSION
      request['Content-Type']      = 'application/json'
      request.body = body

      # TLS with the certificate verified, which is Net::HTTP's own default and
      # is named here because it is not a thing to be turned off.
      Net::HTTP.start(ENDPOINT.host, ENDPOINT.port,
                      use_ssl: true,
                      verify_mode: OpenSSL::SSL::VERIFY_PEER,
                      open_timeout: OPEN_TIMEOUT,
                      read_timeout: READ_TIMEOUT) { |http| http.request(request) }
    rescue Timeout::Error, SystemCallError, SocketError, IOError,
           OpenSSL::SSL::SSLError, Net::HTTPBadResponse => e
      raise TemporaryError, "the request to Claude failed: #{e.message}"
    end

    def content(response)
      case response
      when Net::HTTPSuccess
        answer_text(parse(response.body))
      when Net::HTTPTooManyRequests, Net::HTTPServerError
        raise TemporaryError, "Claude answered #{response.code}: #{reason(response)}"
      else
        raise Error, "Claude answered #{response.code}: #{reason(response)}"
      end
    end

    def parse(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError => e
      raise Error, "Claude answered with something that is not JSON: #{e.message}"
    end

    # The text of the answer, out of the content blocks the Messages API
    # returns. A block of another type -- this API has several -- is not text
    # and is passed over. An answer this plugin cannot find is an error and not
    # an empty description: a Recipe that published the empty string here would
    # have thrown the article away and reported success.
    def answer_text(body)
      blocks = body['content']
      raise Error, 'Claude answered without a content array' unless blocks.is_a?(Array)

      text = blocks.select { |block| block.is_a?(Hash) && block['type'] == 'text' }.
             map { |block| block['text'].to_s }.join.strip
      raise Error, 'Claude answered with no text content' if text.empty?

      text
    end

    # The service's own explanation where it gave one, the status line
    # otherwise. Neither carries the token, and the settings are never logged
    # or raised wholesale.
    def reason(response)
      body = JSON.parse(response.body.to_s)
      error = body['error']
      return error['message'].to_s if error.is_a?(Hash) && !error['message'].to_s.empty?

      response.message.to_s
    rescue JSON::ParserError
      response.message.to_s
    end
  end
end
