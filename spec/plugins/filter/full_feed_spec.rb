# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::FullFeed
# Author::    774 <http://id774.net>
# Created::   Jan 24, 2013
# Updated::   Mar 24, 2013
# Copyright:: 774 Copyright (c) 2013
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'filter/full_feed'

describe Automatic::Plugin::FilterFullFeed do
  context "It should be matched by siteinfo" do
    subject {
      Automatic::Plugin::FilterFullFeed.new(
        {
          'siteinfo' => "items_all.json"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://matome.naver.jp/odai/2129948007339738701/2129948085139809603", "hoge",
            "fuga",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://matome.naver.jp/odai/2129948007339738701/2129948085139809603"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "fuga"

        subject.run

        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://matome.naver.jp/odai/2129948007339738701/2129948085139809603"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should ==
"<div class=\"LyMain\" role=\"main\" data-na=\"NA:main\">\r\n\t<div class=\"ArMain02\" data-na=\"NA:comment\">\r\n\r\n\r\n<script>\r\nvar COMMENT_TARGET_ID = \"PSImipbkFp746BTYcGvB8iizlwODIqiioNZ\";\r\nvar COMMENT_TYPE_CODE = \"R\";\r\nvar COMMENT_ITEM_TOTAL = 0;\r\n</script><a name=\"comment\"></a>\r\n<div id=\"ancMTMComment\" class=\"MdMTMComment01\">\r\n\r\n\t<h2 class=\"mdMTMComment01Ttl\">このまとめへのコメント<span class=\"mdMTMComment01CounterWrap\">（<span class=\"mdMTMComment01Counter\">0</span>）</span>\n</h2>\r\n\r\n\t<div class=\"MdCommentForm01\">\r\n\t<p class=\"mdCommentForm01Input\"><textarea class=\"mdCommentForm01InputTxt\" placeholder=\"追加するコメントを入力\"></textarea></p>\r\n\t<p class=\"mdCommentForm01Btn\"><span class=\"MdBtn01Post01\"><input type=\"button\" value=\"書き込む\" class=\"mdBtn01Post01Btn\" data-na=\"NC:save\"></span></p>\r\n\t</div>\r\n\r\n\t<ul class=\"MdCommentList01\"><!-- /.MdCommentList01 --></ul>\n<div class=\"MdPagination04\" data-na=\"NA:pager\">\r\n\r\n\r\n\r\n\t\t<strong>1</strong>\r\n<!--/MdPagination04-->\n</div>\r\n\r\n<script type=\"text/javascript\">\r\n$(function() {\r\n    nj.Bootloader.done(\"nj.matome.comment\", function() {\r\n        var cl = $(\"ul.MdCommentList01\").mtmCommentSet({\"encryptId\" : COMMENT_TARGET_ID, \"typeCode\": COMMENT_TYPE_CODE});\r\n        $(\".MdPagination04\").njPageNavi({\"item\":0,\"onClickEvent\" : function(e, n){cl.mtmCommentSet(\"setArgs\",{\"page\":n});cl.mtmCommentSet(\"getComment\");}});\r\n    });\r\n});\r\n</script><!--/.MdMTMComment01-->\n</div>\r\n\t<!--/ArMain02-->\n</div>\r\n<!--/LyMain-->\n</div>"

      }
    end
  end

  context "It should be not matched by siteinfo" do
    subject {
      Automatic::Plugin::FilterFullFeed.new(
        {
          'siteinfo' => "items_all.json"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://id774.net", "aaaaaa",
            "bbbbbb",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }})}

    describe "#run" do
      its(:run) { should have(1).feeds }

      specify {
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "bbbbbb"

        subject.run

        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "bbbbbb"
      }
    end
  end

  context "It should be not matched by siteinfo with local dir" do
    subject {
      Automatic::Plugin::FilterFullFeed.new(
        {
          'siteinfo' => "items_all.json"
        },
        AutomaticSpec.generate_pipeline {
          feed {
            item "http://id774.net", "cccc",
            "ddddd",
            "Mon, 07 Mar 2011 15:54:11 +0900"
          }})}

    describe "#run" do
      def cleanup_dir
        root_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
        dir = (File.expand_path('~/.automatic/assets/siteinfo'))
        if File.directory?(dir)
          puts "Removing #{dir}"
          FileUtils.rm_r(dir)
        end
        return dir, root_dir
      end

      before do
        dir, root_dir = cleanup_dir
        FileUtils.mkdir_p(dir)
        FileUtils.cp_r(root_dir + '/assets/siteinfo/items_all.json', dir)
      end

      its(:run) { should have(1).feeds }

      specify {
        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "ddddd"

        subject.run

        subject.instance_variable_get(:@pipeline)[0].items[0].link.
        should == "http://id774.net"
        subject.instance_variable_get(:@pipeline)[0].items[0].description.
        should == "ddddd"
      }

      after do
        cleanup_dir
      end
    end
  end
end
