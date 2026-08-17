# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Filter::SakuraAI
# Description:: Replace each item's description with what the Sakura AI Engine answers.
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Aug 17, 2026
# Updated::     Aug 17, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# One transformation: the item's description goes to the Sakura AI Engine under
# the Recipe's prompt, and the answer becomes the item's description. What that
# transformation is -- a summary, a translation, an extraction, a
# classification -- is the prompt's business, not this plugin's.
#
# The Sakura AI Engine offers an OpenAI-compatible chat completions interface,
# and this plugin is still its own rather than a mode of FilterOpenAI. It is a
# different service: a different endpoint, a different account, a different set
# of models, its own limits and its own errors, and any of those may move
# without OpenAI moving. A Recipe naming FilterSakuraAI says which service the
# text is sent to, which a `provider:` setting would not.
#
# @see https://manual.sakura.ad.jp/cloud/ai-engine/

module Automatic::Plugin
  class FilterSakuraAI
    require 'json'
    require 'net/http'
    require 'openssl'
    require 'uri'

    # The one endpoint the service publishes for this. It is not a setting: an
    # operator has no version of this plugin that talks to a different host,
    # and a setting for it would be a way to send the token somewhere else.
    ENDPOINT = URI('https://api.ai.sakura.ad.jp/v1/chat/completions')

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
      raise ArgumentError, 'FilterSakuraAI needs a token' if token.empty?
      raise ArgumentError, 'FilterSakuraAI needs a model' if model.empty?
      raise ArgumentError, 'FilterSakuraAI needs a prompt' if prompt.empty?
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

    def transform(item)
      text = item.description.to_s
      if text.strip.empty?
        Automatic::Log.puts('warn', "FilterSakuraAI: nothing to send for #{item.link}")
        return
      end

      Automatic::Log.puts('info', "FilterSakuraAI: asking #{model} about #{item.link}")
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
        completion(text)
      rescue TemporaryError => e
        retries += 1
        Automatic::Log.puts('error', "ErrorCount: #{retries}, FilterSakuraAI: #{e.message}")
        if retries <= retry_max
          sleep(@config['interval'].to_i)
          retry
        end
        raise Error, "FilterSakuraAI gave up after #{retries} attempts: #{e.message}"
      end
    end

    def completion(text)
      # The prompt is the system turn and the description is the user turn it
      # is applied to. They are separate messages, so that what an article says
      # is never read as an instruction to this plugin or to the model.
      body = {
        'model' => model,
        'messages' => [
          { 'role' => 'system', 'content' => prompt },
          { 'role' => 'user', 'content' => text }
        ]
      }
      content(post(JSON.generate(body)))
    end

    def post(body)
      request = Net::HTTP::Post.new(ENDPOINT)
      request['Authorization'] = "Bearer #{token}"
      request['Content-Type']  = 'application/json'
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
      raise TemporaryError, "the request to the Sakura AI Engine failed: #{e.message}"
    end

    def content(response)
      case response
      when Net::HTTPSuccess
        answer_text(parse(response.body))
      when Net::HTTPTooManyRequests, Net::HTTPServerError
        raise TemporaryError, "the Sakura AI Engine answered #{response.code}: #{reason(response)}"
      else
        raise Error, "the Sakura AI Engine answered #{response.code}: #{reason(response)}"
      end
    end

    def parse(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError => e
      raise Error, "the Sakura AI Engine answered with something that is not JSON: #{e.message}"
    end

    # The first choice's message content. An answer this plugin cannot find is
    # an error and not an empty description: a Recipe that published the empty
    # string here would have thrown the article away and reported success.
    def answer_text(body)
      choices = body['choices']
      unless choices.is_a?(Array) && choices.first.is_a?(Hash)
        raise Error, 'the Sakura AI Engine answered without a choice'
      end

      message = choices.first['message']
      raise Error, 'the Sakura AI Engine answered without a message' unless message.is_a?(Hash)

      text = message['content'].to_s.strip
      raise Error, 'the Sakura AI Engine answered with no content' if text.empty?

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
