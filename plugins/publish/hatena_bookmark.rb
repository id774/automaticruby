#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::HatenaBookmark
# Author::    774 <http://id774.net>
# Created::   Feb 22, 2012
# Updated::   Feb 24, 2012
# Copyright:: 774 Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class HatenaBookmark
    require 'rubygems'
    require 'time'
    require 'digest/sha1'
    require 'net/http'
    require 'uri'
    #require 'nkf'

    attr_accessor :user

    def initialize
      @user = {
        "hatena_id" => "",
        "password"  => ""
      }
    end

    def wsse(hatena_id, password)
      # Unique value
      nonce = [Time.now.to_i.to_s].pack('m').gsub(/\n/, '')
      now = Time.now.utc.iso8601
      
      # Base64 encoding for SHA1 Digested strings
      digest = [Digest::SHA1.digest(nonce + now + password)].pack("m").gsub(/\n/, '')
      
      {'X-WSSE' => sprintf(
                           %Q<UsernameToken Username="%s", PasswordDigest="%s", Nonce="%s", Created="%s">,
                           hatena_id, digest, nonce, now)
      }
    end

    def toXml(link, summary)
      %Q(
      <entry xmlns="http://purl.org/atom/ns#">
      <title>dummy</title>
      <link rel="related" type="text/html" href="#{link}" />
      <summary type="text/plain">#{summary}</summary>
      </entry>
    )
    end

    def post(b_url, b_comment)
      url = "http://b.hatena.ne.jp/atom/post"
      header = wsse(@user["hatena_id"], @user["password"])
      uri = URI.parse(url)
      proxy_class = Net::HTTP::Proxy(ENV["PROXY"], 8080)
      http = proxy_class.new(uri.host)
      http.start {|http|
        # b_url = NKF.nkf('-w', b_url)
        # b_comment = NKF.nkf('-w', b_comment)
        res = http.post(uri.path, toXml(b_url, b_comment), header)
        t = Time.now.strftime("%Y/%m/%d %X")
        if res.code == "201" then
          unless b_comment.nil?
            print "#{t} [info] Success: #{b_url} Comment: #{b_comment}\n"
          else
            print "#{t} [info] Success: #{b_url}\n"
          end
        else
          print "#{t} [error] #{res.code} Error: #{b_url}\n"
        end
      }
    end
  end

  class PublishHatenaBookmark
    attr_accessor :hb

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline

      @hb = HatenaBookmark.new
      @hb.user = {
        "hatena_id" => @config['username'],
        "password"  => @config['password']
      }
    end

    def run
      @pipeline.each {|feeds|
        unless feeds.nil?
          feeds.items.each {|feed|
            Automatic::Log.puts("info", "Bookmarking: #{feed.link}")
            hb.post(feed.link, nil)
            sleep @config['interval'].to_i
          }
        end
      }
      @pipeline
    end
  end
end
