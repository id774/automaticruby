# -*- coding: utf-8 -*-
# Name::        Automatic::Plugin::Publish::HatenaBookmark
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 22, 2012
# Updated::     Aug 15, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
#
# STATUS: Needs rework. This speaks the WSSE AtomPub interface, which Hatena
# has superseded with an OAuth one. The service and the bookmarking API are
# both current; this client is not, and restoring it means the current
# endpoint and the current authentication rather than a change of a few lines.
# See doc/PLUGINS.md section 6.7.
#
# The transport was corrected in the meantime: the request is made over HTTPS,
# so that an operator who runs this does not put a password digest on the wire
# in the clear. That is a defect worth not shipping whatever the plugin's
# status is; it is not a claim that the plugin works.

require 'digest/sha1'
require 'net/http'
require 'securerandom'
require 'time'
require 'uri'

module Automatic::Plugin
  class HatenaBookmark
    ENDPOINT = 'https://b.hatena.ne.jp/atom/post'
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30

    attr_accessor :user

    def initialize
      @user = { 'hatena_id' => '', 'password' => '' }
    end

    def wsse(hatena_id, password)
      nonce  = SecureRandom.random_bytes(16)
      now    = Time.now.utc.iso8601
      digest = [Digest::SHA1.digest(nonce + now + password.to_s)].pack('m0')

      { 'X-WSSE' => format('UsernameToken Username="%s", PasswordDigest="%s", ' \
                           'Nonce="%s", Created="%s"',
                           hatena_id, digest, [nonce].pack('m0'), now) }
    end

    def to_xml(link, summary)
      <<~XML
        <entry xmlns="http://purl.org/atom/ns#">
        <title>dummy</title>
        <link rel="related" type="text/html" href="#{link}" />
        <summary type="text/plain">#{summary}</summary>
        </entry>
      XML
    end

    def post(url, comment)
      Automatic::Log.puts('info', "Bookmarking: #{url}")
      uri     = URI.parse(ENDPOINT)
      request = Net::HTTP::Post.new(uri.path, wsse(@user['hatena_id'], @user['password']))
      request.body = to_xml(url, comment)

      response = start(uri) { |http| http.request(request) }
      log(response, url, comment)
    end

    private

    def start(uri, &block)
      proxy = Net::HTTP.Proxy(ENV.fetch('PROXY', nil), 8080)
      proxy.start(uri.host, uri.port,
                  use_ssl: true,
                  open_timeout: OPEN_TIMEOUT,
                  read_timeout: READ_TIMEOUT, &block)
    end

    def log(response, url, comment)
      if response.code == '201'
        message = "Success: #{url}"
        message += " Comment: #{comment}" unless comment.nil?
        Automatic::Log.puts(:info, message)
      else
        Automatic::Log.puts(:error, "#{response.code} Error: #{url}")
      end
    end
  end

  class PublishHatenaBookmark
    attr_accessor :hb

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline

      @hb = HatenaBookmark.new
      @hb.user = {
        'hatena_id' => @config['username'],
        'password'  => @config['password']
      }
    end

    def run
      @pipeline.each do |feeds|
        next if feeds.nil?

        feeds.items.each do |feed|
          hb.post(absolute(feed.link), nil)
          sleep(@config['interval'].to_i)
        end
      end
      @pipeline
    end

    private

    def absolute(link)
      string = link.to_s
      return string if string.match?(%r{\Ahttps?://})
      return "https:#{string}" if string.start_with?('//')

      "https://#{string}"
    end
  end
end
