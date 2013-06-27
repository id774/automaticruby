# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Mail
# Author::    774 <http://id774.net>
# Created::   Apr 5, 2012
# Updated::   Apr 5, 2012
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishMail
    require 'action_mailer'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      Mailer.smtp_settings = default_setting.update(
        {
          :port           => @config["port"],
         #:address        => @config["address"],
         #:authentication => @config["auth"],
         #:user_name      => @config["username"],
         #:password       => @config["password"],
         #:domain         => @config["domain"],
        })

      Mailer.raise_delivery_errors = true
      @pipeline.each { |feeds|
        unless feeds.nil?
          feeds.items.each { |feed|
            Mailer.notify(@config, feed)
          }
        end
      }
      @pipeline
    end

    def default_setting
      return {}
    end

    class Mailer < ActionMailer::Base
      def notify(option, feed)
        m = mail(
          :date    => Time.now,
          :subject => feed.title,
          :to      => option["mailto"],
         #:cc      => option["mailcc"],
         #:bcc     => option["mailbcc"],
          :from    => option["mailfrom"])

        unless feed.content_encoded.nil?
          m.body = feed.content_encoded
        else
          m.body = feed.description
        end

        m.deliver
      end
    end
  end
end
