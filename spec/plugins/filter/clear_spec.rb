# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Clear
# Author::    774 <http://id774.net>
# Created::   Oct 20, 2014
# Updated::   Oct 20, 2014
# Copyright:: Copyright (c) 2014 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/clear'

describe Automatic::Plugin::FilterClear do

  context "should be cleared" do
    subject {
      Automatic::Plugin::FilterClear.new({
      },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://hogefuga.com", "",
            "aaaabbbccc"
          }
          feed {
            item "http://aaaabbbccc.com", "",
            "hogefugahoge"
          }
          feed {
            item "http://aaabbbccc.com", "",
            "aaaaaaaaaacccdd"
          }
          feed {
            item "http://aaccc.com", "",
            "aaaabbbccc"
            item "http://aabbccc.com", "",
            "aabbbccc"
          }
          feed {
            item "http://cccddd.com", "",
            "aabbbcccdd"
          }
        }
      )}

    describe "#run" do
      its(:run) { should have(0).feeds }
    end
  end
end
