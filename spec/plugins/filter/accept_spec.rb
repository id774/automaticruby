# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::Accept
# Author::    soramugi <http://soramugi.net>
# Created::   Jun  4, 2013
# Updated::   Jun  4, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/accept'

describe Automatic::Plugin::FilterAccept do

  context "with contain by title" do

    subject {
      Automatic::Plugin::FilterAccept.new({
        'title' => [""],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com", "foo" }
          feed { item "http://google.com", "hi" }
        })
    }

    describe "#run" do
      its(:run) { should have(2).feeds }
    end
  end

  context "with contain by title" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'title' => ["foo"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com", "foo" }
          feed { item "http://google.com", "hi" }
          feed { item "http://google.com", "hi" }
        })
    }

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end

  context "with contain by title" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'title' => ["o"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com", "foo" }
          feed { item "http://google.com", "hi" }
        })
    }

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end

  context "with contain by links" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'link' => ["comment"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(0).feeds }
    end
  end

  context "with contain by links" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'link' => ["comment"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com/comment" }
        })
    }

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end

  context "with contain by links" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'link' => ["hoge"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(0).feeds }
    end
  end

  context "with contain by links" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'link' => ["hoge"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com/hoge" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end

  context "with contain by links" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'link' => ["github"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(1).feeds }
    end
  end

  context "with contain by links" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'link' => [""],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(2).feeds }
    end
  end

  context "with contain by description" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'description' => ["comment"],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(0).feeds }
    end
  end

  context "with contain by description" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'description' => [""],
      },
        AutomaticSpec.generate_pipeline {
          feed { item "http://github.com" }
          feed { item "http://google.com" }
        })
    }

    describe "#run" do
      its(:run) { should have(2).feeds }
    end
  end

  context "with contain by description" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'description' => ["bbb"],
      },
        AutomaticSpec.generate_pipeline {
          # url, title, description, pubDate, author, source, enclosure
          feed {
            item "http://hogefuga.com", "",
            "aaabbbccc"
          }
          feed {
            item "http://aaabbbccc.com", "",
            "hogefugahoge"
          }
          feed {
            item "http://aaabbbccc.com", "",
            "aaaccc"
          }
          feed {
            item "http://aaaccc.com", "",
            "aaabbbccc"
          }
        }
      )}

    describe "#run" do
      its(:run) { should have(2).feeds }
    end
  end

  context "with contain by description" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'description' => ["aaaa"],
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
            item "http://aaaaccc.com", "",
            "aabbbccc"
          }
          feed {
            item "http://aaaaccc.com", "",
            "aabbbcccdd"
          }
        }
      )}

    describe "#run" do
      its(:run) { should have(2).feeds }
    end
  end

  context "with item base contain by links" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'link' => ["dddd"],
      },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://hogefuga.com", "",
            "aaaabbbccc"
            item "http://hogefuga.com", "",
            "aaaabbbcccdddd"
          }
          feed {
            item "http://aaaabbbccc.com", "",
            "hogefugahoge"
          }
          feed {
            item "http://aaabbbcccdddd.com", "",
            "aaaaaaaaaacccdd"
          }
          feed {
            item "http://aaaaccc.com", "",
            "aabbbccc"
            item "http://aabbcccdddd.com", "",
            "aabbbcccddd"
          }
          feed {
            item "http://cccdddd.com", "",
            "aabbbcccdd"
          }
        }
      )}

    describe "#run" do
      its(:run) { should have(3).feeds }
    end
  end

  context "with item base contain by description" do
    subject {
      Automatic::Plugin::FilterAccept.new({
        'description' => ["aaaa"],
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
      its(:run) { should have(3).feeds }
    end
  end
end
