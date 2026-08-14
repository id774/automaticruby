# Quick Start

This guide takes public information through one short Automatic Ruby pipeline
and leaves it as Markdown. It needs no account, credential, paid service or
database server, and no gem beyond the four `gem install automatic` brings —
no HTML parser, no database, nothing to build.

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

  - module: PublishMarkdown
    config:
      file: ~/.automatic/markdown/feeds.md
      mode: append
```

Run the scaffolded copy:

```sh
automatic -c ~/.automatic/config/example/feed2markdown.yml
```

`SubscriptionFeed` acquires the public Ruby news feed. `PublishMarkdown`
appends those items to a plain-text document, reducing the HTML in each item's
body to text as it goes.

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

Run the Recipe again, and the same items are appended a second time: nothing in
this Recipe remembers what it has already published. The next step is what
fixes that.

## 5. Collect only what is new

A store plugin records what has been published and passes on only what has not.
`StorePermalink` keeps that record in SQLite through ActiveRecord, and those two
gems are the store plugins' own dependencies rather than the framework's, so
they are installed when they are wanted:

```sh
gem install activerecord sqlite3
```

Then put the plugin between the two the Recipe already has:

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

Run it twice. The second run appends nothing, which is what makes the Recipe
safe to run from `cron` — and, in general, what to do before any plugin with an
effect. Other plugins have optional dependencies of their own, all listed in
[`DEPLOYMENT.md`](DEPLOYMENT.md).

## 6. Run it from cron

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

The normal installation above remains the quickest way to use Automatic Ruby.
To try the development version or change the source, first follow
[README's checkout setup](../README.md#from-a-checkout). Then run the same flow
through the checkout's executable:

```sh
bundle exec bin/automatic scaffold
bundle exec bin/automatic -c ~/.automatic/config/example/feed2markdown.yml
```

A checkout resolves gems through Bundler rather than through RubyGems, so step 5
is done differently there: `bundle config set --local with store` and
`bundle install`, instead of `gem install activerecord sqlite3`. See
[`DEPLOYMENT.md`](DEPLOYMENT.md).

The Recipe is ordinary YAML. Change the feed URL, insert a supported Filter, or
change the Markdown path without changing the framework. To write a small
plugin, continue with [`PLUGIN_DEVELOPMENT.md`](PLUGIN_DEVELOPMENT.md).
