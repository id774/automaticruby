# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::Gemini
# Description:: Replace each item's description with what the Google Gemini API answers.
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 17, 2026
# Updated::     Aug 17, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# One transformation: the item's description goes to the Gemini API under the
# Recipe's prompt, and the answer becomes the item's description. What that
# transformation is -- a summary, a translation, an extraction, a
# classification -- is the prompt's business, not this plugin's.
#
# This plugin knows Gemini and nothing else. Its model is named in the URL
# rather than in the body, its API key is a header of its own, and its request
# and answer are built of `contents` and `parts`. None of that is bent into
# another service's shape, and no other service's request is built here.
#
# It speaks `generateContent`, which Google states remains fully supported and
# is the single-turn text interface: a request that carries an instruction and
# a text and answers with a text, which is exactly what this plugin does.
# @see https://ai.google.dev/api/generate-content

module Automatic::Plugin
  class FilterGemini
    require 'json'
    require 'net/http'
    require 'openssl'
    require 'uri'

    # The model is part of the path here, unlike every other service in this
    # directory, so the endpoint is built per Recipe rather than being one
    # constant.
    ENDPOINT_FORMAT = 'https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent'.freeze

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
      raise ArgumentError, 'FilterGemini needs a token' if token.empty?
      raise ArgumentError, 'FilterGemini needs a model' if model.empty?
      raise ArgumentError, 'FilterGemini needs a prompt' if prompt.empty?

      endpoint
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

    # A model name that cannot go in a URL is the Recipe's mistake, and is
    # reported as one rather than as a failed request.
    def endpoint
      @endpoint ||= URI(format(ENDPOINT_FORMAT, model))
    rescue URI::InvalidURIError
      raise ArgumentError, "FilterGemini cannot build a request for the model #{model}"
    end

    def transform(item)
      text = item.description.to_s
      if text.strip.empty?
        Automatic::Log.puts('warn', "FilterGemini: nothing to send for #{item.link}")
        return
      end

      Automatic::Log.puts('info', "FilterGemini: asking #{model} about #{item.link}")
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
        generated(text)
      rescue TemporaryError => e
        retries += 1
        Automatic::Log.puts('error', "ErrorCount: #{retries}, FilterGemini: #{e.message}")
        if retries <= retry_max
          sleep(@config['interval'].to_i)
          retry
        end
        raise Error, "FilterGemini gave up after #{retries} attempts: #{e.message}"
      end
    end

    def generated(text)
      # The prompt is the system instruction and the description is the content
      # it is applied to. They are separate fields, so that what an article
      # says is never read as an instruction to this plugin or to the model.
      body = {
        'system_instruction' => { 'parts' => [{ 'text' => prompt }] },
        'contents' => [{ 'role' => 'user', 'parts' => [{ 'text' => text }] }]
      }
      content(post(JSON.generate(body)))
    end

    def post(body)
      request = Net::HTTP::Post.new(endpoint)
      # The key goes in a header rather than in the query string, which is the
      # way Google documents and the way that keeps a credential out of a URL.
      request['x-goog-api-key'] = token
      request['Content-Type']   = 'application/json'
      request.body = body

      # TLS with the certificate verified, which is Net::HTTP's own default and
      # is named here because it is not a thing to be turned off.
      Net::HTTP.start(endpoint.host, endpoint.port,
                      use_ssl: true,
                      verify_mode: OpenSSL::SSL::VERIFY_PEER,
                      open_timeout: OPEN_TIMEOUT,
                      read_timeout: READ_TIMEOUT) { |http| http.request(request) }
    rescue Timeout::Error, SystemCallError, SocketError, IOError,
           OpenSSL::SSL::SSLError, Net::HTTPBadResponse => e
      raise TemporaryError, "the request to Gemini failed: #{e.message}"
    end

    def content(response)
      case response
      when Net::HTTPSuccess
        answer_text(parse(response.body))
      when Net::HTTPTooManyRequests, Net::HTTPServerError
        raise TemporaryError, "Gemini answered #{response.code}: #{reason(response)}"
      else
        raise Error, "Gemini answered #{response.code}: #{reason(response)}"
      end
    end

    def parse(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError => e
      raise Error, "Gemini answered with something that is not JSON: #{e.message}"
    end

    # The text of the first candidate. A response with no candidate is what a
    # request stopped by a safety filter looks like, and it is an error rather
    # than an empty description: a Recipe that published the empty string here
    # would have thrown the article away and reported success.
    def answer_text(body)
      candidates = body['candidates']
      unless candidates.is_a?(Array) && candidates.first.is_a?(Hash)
        raise Error, 'Gemini answered without a candidate'
      end

      parts = candidates.first.dig('content', 'parts')
      raise Error, 'Gemini answered without content parts' unless parts.is_a?(Array)

      text = parts.select { |part| part.is_a?(Hash) }.map { |part| part['text'].to_s }.join.strip
      raise Error, 'Gemini answered with no text' if text.empty?

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
