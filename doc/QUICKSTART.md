# Quick Start

This guide takes four public pages through one short Automatic Ruby pipeline and
leaves what they publish as one Markdown document. It needs no account, no
credential, no paid service and no database server.

It does need two of the optional gems — because of the plugins the Recipe
names, not because of the framework — and installing exactly those is a step of
this guide rather than a footnote to it. Automatic Ruby installs what the
framework needs and leaves a plugin's gems to the operator who uses that
plugin, so "which plugins does this Recipe name, and what do they need" is a
question every Recipe asks. Skipping it is the usual way a first run stops half
way through.

## 1. Install

Use Ruby 3.3 through 4.0 on a Unix-like system:

```sh
ruby -v
gem install automatic
automatic --version
```

Working from a Git checkout instead is this same guide with one step done
differently; "From a source checkout" at the end is that step.

## 2. Create the user directory

```sh
automatic scaffold
```

This creates `~/.automatic` and copies the shipped examples to
`~/.automatic/config/example`. Existing files and directories are not
overwritten.

## 3. Write the Recipe

A Recipe is one job: the plugins it runs, in order, with their settings. This
one reads four public index pages as HTML and makes a feed of the articles each
lists — which is what to do for a page whose feed you do not have — keeps a
record of what it has already seen, and appends the rest to a Markdown
document.

Write it to `~/.automatic/config/web2markdown.yml`:

```yaml
plugins:
  - module: CustomFeedWeb
    config:
      retry: 2
      interval: 2
      sites:
        # Articles: https://blog.python.org/2026/08/python-3147-31315/
        - name: Python Insider
          url: https://blog.python.org/
          link_selector: 'a[href]'
          include:
            - '^https://blog\.python\.org/20[0-9]{2}/[0-9]{2}/[^/]+/?$'
          same_host: true
          fetch_items: 20

        # Articles: https://blog.rust-lang.org/2026/08/04/enabling-polonius-alpha-on-nightly/
        - name: Rust Blog
          url: https://blog.rust-lang.org/
          link_selector: 'a[href]'
          include:
            - '^https://blog\.rust-lang\.org/20[0-9]{2}/[0-9]{2}/[0-9]{2}/[^/]+/?$'
          same_host: true
          fetch_items: 20

        # Articles: https://go.dev/blog/pkgsite-api
        - name: The Go Blog
          url: https://go.dev/blog/
          link_selector: 'a[href]'
          include:
            - '^https://go\.dev/blog/[^/]+$'
          same_host: true
          fetch_items: 20

        # Alerts: https://www.jpcert.or.jp/at/2026/at260021.html
        - name: JPCERT/CC Alerts
          url: https://www.jpcert.or.jp/at/2026.html
          link_selector: 'a[href]'
          include:
            - '^https://www\.jpcert\.or\.jp/at/20[0-9]{2}/at[0-9]+\.html$'
          same_host: true
          fetch_items: 20

  - module: StoreDigest
    config:
      db: web2markdown.db
      fields:
        - title
        - link

  - module: PublishMarkdown
    config:
      file: ~/.automatic/markdown/web.md
      mode: append
```

Three plugins, and each hands its result to the next:

- **`CustomFeedWeb`** fetches each page and makes a feed of the article links it
  lists. `include` is what tells an article from a navigation link, `interval`
  is the pause between requests, and one run makes one request per site —
  nothing here follows a link or reads an article body.
- **`StoreDigest`** records a digest of each item and passes on only the items
  whose digest it had not recorded already. It is what makes the Recipe safe to
  run repeatedly. `db` is a **file name**, kept under `~/.automatic/db`.
- **`PublishMarkdown`** appends what is left to a plain-text document, creating
  the directory if it is missing. Its `file`, unlike `db`, is a path.

## 4. Install what the Recipe needs

Read the Recipe you have just written, plugin by plugin, and look each one up in
the table of optional plugin dependencies in [`DEPLOYMENT.md`](DEPLOYMENT.md).
That table gives, for these three:

- **`CustomFeedWeb`** — `nokogiri`, which it reads the pages with. In a
  checkout, the group `html`.
- **`StoreDigest`** — `activerecord` and `sqlite3`, which it keeps its record
  in. In a checkout, the group `store`.
- **`PublishMarkdown`** — nothing of its own.

```sh
gem install nokogiri
gem install activerecord sqlite3
```

**Install what the whole Recipe needs, not what its first plugin needs.** A
plugin is loaded when the pipeline reaches it, so installing only `nokogiri`
would let `CustomFeedWeb` fetch its pages, hand its feeds on, and stop the run
where the next plugin is loaded:

```text
automatic: The `activerecord` gem is not installed. It is needed by the store
plugins. Install it with `gem install activerecord`, or in a source checkout add
its group to the bundle; see the optional plugin dependencies in
doc/DEPLOYMENT.md. (cannot load such file -- active_record)
```

`PublishMarkdown` is the entry worth reading twice: it needs no gem of its own,
using an HTML parser where one is installed and its own substitution where none
is. A plugin's row in that table is the answer, not a guess from what the
plugin does.

`nokogiri` and `sqlite3` build a native extension where no binary package
matches your platform. Install a build environment only if one of them says it
needs one.

## 5. Run it

```sh
automatic -c ~/.automatic/config/web2markdown.yml
```

A bare name is resolved inside `~/.automatic/config`, so `automatic -c
web2markdown.yml` is the same command. The log names each page as it is fetched,
each digest as it is saved, and the document as it is written.

## 6. Read the result

```sh
sed -n '1,80p' ~/.automatic/markdown/web.md
```

Each item is a level-2 heading followed by the metadata the feed carries:

```markdown
## Extending the pkgsite API

- Link: <https://go.dev/blog/pkgsite-api>
- Date: 2026-08-17 09:00:00 +0900
```

## 7. Run it again

```sh
automatic -c ~/.automatic/config/web2markdown.yml
```

The second run appends nothing: the pages still list the same articles, and
`StoreDigest` has the digest of every one of them. An article published between
the two runs is the one thing that would be added — which is what makes this
Recipe safe to put in `cron`, and what to check before any Recipe with an
effect.

If instead everything is appended a second time, the store plugin is writing
somewhere other than where you think. The `Using Database:` line of the log
names the file it opened.

## 8. Run it from cron

Create the log directory once, then use the absolute path reported by
`command -v automatic`:

```sh
mkdir -p ~/.automatic/log
command -v automatic
```

```crontab
0 * * * * /usr/local/bin/automatic -c $HOME/.automatic/config/web2markdown.yml >> $HOME/.automatic/log/web2markdown.log 2>&1
```

Automatic Ruby runs once and exits; `cron` supplies the schedule.

## From a source checkout

The normal installation above remains the quickest way to use Automatic Ruby. To
try the development version or change the source, first follow
[README's checkout setup](../README.md#from-a-checkout). Every `automatic` above
then becomes `bundle exec bin/automatic`, run from the checkout directory:

```sh
cd ~/automaticruby
bundle exec bin/automatic scaffold
bundle exec bin/automatic -c ~/.automatic/config/web2markdown.yml
```

Step 4 is the step that differs, because a checkout resolves its gems through
Bundler rather than through RubyGems. Each optional gem is in a Bundler group,
and the Recipe's groups — `html` and `store`, from step 4 — are selected
together and installed once:

```sh
bundle config set --local with "html store"
bundle install
```

`gem install nokogiri` does **not** work here: the gem installs, and the
checkout still reports it as missing, because it is not in the bundle. That
difference, the commands that show what the bundle holds, and the same three
plugins taken step by step through choosing their groups are in
[`DEPLOYMENT.md`](DEPLOYMENT.md) under "Working out what a Recipe needs, in a
checkout".

## Next

The Recipe is ordinary YAML. Add a site, change the Markdown path, or put
`PublishConsoleLink` at the end to see what the pipeline holds without writing
anything. The shipped `feed2markdown.yml` and `feed2console.yml` in
`~/.automatic/config/example` are the same shape over an ordinary feed, for a
site that publishes one.

Taking this same pipeline further — the article bodies, one joined text, and an
AI service asked one question about it — is
[`AI_TUTORIAL.md`](AI_TUTORIAL.md).

What each plugin does is [`PLUGINS.md`](PLUGINS.md) section 6; installing,
scheduling and operating a Recipe is [`DEPLOYMENT.md`](DEPLOYMENT.md); writing a
small plugin of your own is
[`PLUGIN_DEVELOPMENT.md`](PLUGIN_DEVELOPMENT.md).
