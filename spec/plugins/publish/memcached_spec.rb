# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Publish::Memcached
# Author::    774 <http://id774.net>
# Created::   Jun 25, 2013
# Updated::   Jun 25, 2013
# Copyright:: Copyright (c) 2012-2013 Automatic Ruby Developers.
# License::   Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0.

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')

require 'publish/memcached'

describe Automatic::Plugin::PublishMemcached do
  context 'when feed' do
    describe 'should put the feeds to memcached' do
      subject {
        Automatic::Plugin::PublishMemcached.new(
          {
            'host' => "localhost",
            'port' => "11211",
            'key'  => "rspec"
          },
          AutomaticSpec.generate_pipeline{
            feed {
              item "http://blog.id774.net/post/2012/01/30/18/", "ブログをはじめた",
              "なぜいまブログなのか
              
              いままでインターネット全体に公開するブログとして、はてなダイアリーを利用してきた。それ以外のある程度まとまった文章は Facebook に書いてきた。それはそれで良かったのだけど、いろいろと思うところもあり、このたび新しくブログをはじめることにした。
              
              はてなダイアリーはシンタックスハイライト (プログラミング言語の色付けのこと) が充実していたので利用していた。しかし最近登場した CoffeeScript や Haml のような新しい言語には対応していない。新しくはてなブログというのも始まったが、ダイアリー以上にシンタックスハイライトが使えないようだ。
              
              そこで、今後インターネット上で文章を書いていくにあたりどうするか考えた。"
              item "http://blog.id774.net/post/2012/01/30/38/", "Twitter Viewer つくった",
              "Twitter を閲覧するための Web アプリをつくった。
              
              Twitter Viewer
              
              やっていることは至ってシンプルで RDB にためた発言をブラウザに表示させているだけである。内容は Rails の Scaffold ほとんどそのまま。 CSS はサイトローカルな Bootstrap を読み込んでいる。簡単なアプリだが、ブラウザにいちど表示させてしまえば電波が入らない地下鉄などでもゆっくり読めるので、モバイル環境で大量の発言をざっとチェックしたいときなどに使えて意外と実用的である。発言のクロールは別途おこなう必要がある。この例では Termtter の ActiveRecord プラグインを利用している。"
              item "http://blog.id774.net/post/2012/01/30/48/", "PC-98 とエミュレータ",
              "Facebook には少し書いたのだが、今年に入ってから 90 年代に使っていた PC-98 と呼ばれる PC を発掘したので起動した。もう 15 年前後も経っているというのに正常に利用することができて感動してしまった。あの ThinkPad ですら数年ほど電源を入れないで放置しておくと起動しないことが多いのに、さすが発売当初 40 〜 50 万円程もした高級マシンである。そんなわけで今回は PC-98 の話。
              
              PC-98 のソフトを使う
              当時のソフトウェアを利用するためには以下のものが必要だ。
              1. PC-98 エミュレータ
              2. MS-DOS (オペレーティングシステム)
              3. 動作させる対象のソフトウェア"
            }
            feed {
              item "http://d.hatena.ne.jp/Naruhodius/20120130/1327862031", "ブログを移転しました",
              "いままでこの「はてなダイアリー」にブログを書いてきましたが、以下のアドレスにブログを移転することにしました。このブログはもう更新されません。以下の新しいブログを購読してください。"
            }
          }
        )
      }

      its (:run) {
        fluentd = mock("memcached")
        subject.run.should have(2).feed
      }
    end

  end
end
