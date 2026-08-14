# Quick Start

This guide takes public information through one short Automatic Ruby pipeline
and leaves it as Markdown. It needs no account, credential, paid service or
database server, and no gem beyond the ones `gem install automatic` brings.

## 1. Install

Use Ruby 3.3 through 4.0 on a Unix-like system:

```sh
ruby -v
gem install automatic
automatic --version
```

## 2. Create the user directory

```sh
automatic scaffold
```

This creates `~/.automatic` and copies the shipped examples to
`~/.automatic/config/example`. Existing files and directories are not
overwritten.

## 3. Run the example

The installed example is `config/feed2markdown.yml` in this repository:

```yaml
plugins:
  - module: SubscriptionFeed
    config:
      feeds:
        - https://www.ruby-lang.org/en/feeds/news.rss

  - module: StorePermalink
    config:
      db: feed2markdown.db

  - module: PublishMarkdown
    config:
      file: ~/.automatic/markdown/feeds.md
      mode: append
```

Run the scaffolded copy:

```sh
automatic -c ~/.automatic/config/example/feed2markdown.yml
```

`SubscriptionFeed` acquires the public Ruby news feed. `StorePermalink` keeps a
local SQLite record and passes on only unseen items. `PublishMarkdown` appends
those items to a plain-text document.

## 4. Read the result

```sh
sed -n '1,80p' ~/.automatic/markdown/feeds.md
```

Each item is a level-2 heading followed by available metadata and a text body:

```markdown
## Item title

- Link: <https://example.com/item>
- Date: 2026-08-14 10:00:00 +0000

Item body.
```

Run the Recipe again. Items already recorded by `StorePermalink` are not
appended again.

## 5. Run it from cron

Create the log directory once, then use the absolute path reported by
`command -v automatic`:

```sh
mkdir -p ~/.automatic/log
command -v automatic
```

```crontab
0 * * * * /usr/local/bin/automatic -c $HOME/.automatic/config/example/feed2markdown.yml >> $HOME/.automatic/log/feed2markdown.log 2>&1
```

Automatic Ruby runs once and exits; `cron` supplies the schedule.

## From a source checkout

```sh
bundle install
bundle exec bin/automatic scaffold
bundle exec bin/automatic -c ~/.automatic/config/example/feed2markdown.yml
```

The Recipe is ordinary YAML. Change the feed URL, insert a supported Filter, or
change the Markdown path without changing the framework. To write a small
plugin, continue with [`PLUGIN_DEVELOPMENT.md`](PLUGIN_DEVELOPMENT.md).
