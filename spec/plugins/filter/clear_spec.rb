# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Clear
# Author: id774 (More info: http://id774.net)
# Source Code: https://github.com/id774/automaticruby
# License: The GPL version 3, or LGPL version 3 (Dual License).
# Contact: idnanashi@gmail.com
# Created::   Oct 20, 2014
# Updated::   Oct 20, 2014
# Copyright:: Copyright (c) 2014 Automatic Ruby Developers.

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
