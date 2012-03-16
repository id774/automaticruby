# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Smtp
# Author::    kzgs
# Created::   Mar 17, 2012
# Updated::   Mar 17, 2012
# Copyright:: kzgs Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

module Automatic::Plugin
  class PublishSmtp
    require 'action_mailer'

    def initialize(config, pipeline=[])
      @config = config
      @pipeline = pipeline
    end

    def run
      Mailer.smtp_settings = default_setting.update(
        {
          :port => @config["port"],
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
        m = mail(:subject => option["subject"],
          :to => option["mailto"],
          :from => option["mailfrom"])
        m.body = feed.link
        m.deliver
      end
    end
  end
end
