#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Config::Validator
# Author::    aerith <http://aerith.sc/>
# Created::   Feb 23, 2012
# Updated::   Feb 23, 2012
# Copyright:: Copyright (c) 2012
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

class Automatic
  module Config
    class Validator
      attr_accessor :config, :result

      class InvalidException < Exception; end;

      def initialize(config = nil)
        @config = config || {}
        @result = ValidateResult.new
      end

      def validate(klass, config = nil)
        return true if config.nil?
        return true if not config.is_a?(Hash)
        return true if not klass.respond_to?(:rules)

        rules = klass.rules
        return true if not rules.is_a?(Hash)

        process(rules, config).result.valid?
      end

      private
      def process(rules, config)
        errors = {}

        rules.each do |key, rule|
          name = key.to_sym

          rule.each do |method, args|
            unless ValidateRule.send(method, *[config, name, args])
              errors[name] = {} if errors[name].nil? or errors.size < 1
              errors[name][method] = true
              if @config["stop_on_invalid"] and errors[name][method]
                raise InvalidException
              end
            end
          end
        end

        @result.errors = errors

        self
      end

      class ValidateResult
        attr_accessor :errors

        def error(name)
          errors.exists?(name)
        end

        def valid?
          errors.empty?
        end
      end

      module ValidateRule
        def self.required(config, name, *args)
          return true unless args.size < 1 or args.first
          return true if not config[name.to_s].nil? and not config[name.to_s].empty?
          false
        end

        def self.default(config, name, *args)
          config[name.to_s] ||= args.first 
          true
        end
      end
    end
  end
end

