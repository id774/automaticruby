# Automatic Ruby

**A Ruby framework for general-purpose automatic processing.**

Automatic Ruby runs jobs that you *assemble* rather than write. A step is a
plugin — a small Ruby class with one method. A job is a **Recipe** — a YAML file
naming the plugins in order, with their settings. Running the job is one
command, which is safe to put in `cron`.

```yaml
plugins:
  - module: SubscriptionFeed
    config:
      feeds:
        - https://www.ruby-lang.org/en/feeds/news.rss

  - module: StorePermalink
    config:
      db: seen.db

  - module: PublishMarkdown
    config:
      file: ~/notes/feeds.md
```

```sh
automatic -c my_recipe.yml
```

Fetch a public feed, remember what has already been seen, and write the new
items into a Markdown file: readable by people, reusable by
tools, ready to hand to an AI. Change the last plugin and the same pipeline
prints to the terminal instead, or downloads the images, or forwards them to
Fluentd, or writes them to a database. Write your own plugin and it composes
with all the others.

**[Follow the Quick Start](doc/QUICKSTART.md)** to install the gem, scaffold the
example, and produce Markdown from the public Ruby news feed.

---

## Contents

1. [Overview](#1-overview)
2. [Features](#2-features)
3. [Architecture](#3-architecture)
4. [Supported environment](#4-supported-environment)
5. [Installation](#5-installation)
6. [Quick start](#6-quick-start)
7. [Recipes](#7-recipes)
8. [Plugins](#8-plugins)
9. [CLI usage](#9-cli-usage)
10. [Configuration](#10-configuration)
11. [The user directory](#11-the-user-directory)
12. [Testing](#12-testing)
13. [Development](#13-development)
14. [Repository structure](#14-repository-structure)
15. [Documents](#15-documents)
16. [Versioning](#16-versioning)
17. [License](#17-license)

---

## 1. Overview

A recurring job usually has the same shape: fetch something, decide which parts
of it are new or interesting, keep a record so the same item is not handled
twice, and send the result somewhere. Writing each such job as a script means
writing the fetching, the filtering, the de-duplication and the retrying again
every time.

"Somewhere" is often a file. A Recipe that ends in `PublishMarkdown` leaves what
it collected as a Markdown document: a person reads it as it is, `grep` searches
it, Git keeps its history, and a program — a language model or an agent among
them — takes it as input without a parser or an API. That is the general case,
and it needs no account anywhere; the plugins that publish to a service are for
when a particular service is the point.

Automatic Ruby exists so that those jobs are assembled instead. It contributes
exactly three things:

- **a uniform contract** every step obeys, so that steps compose,
- **one value** passed from step to step, so that they have something to compose
  over,
- **a loader** that finds a step by name, so that a Recipe can name it.

Everything else is a plugin. The framework is under seven hundred lines of Ruby
and is meant to stay that size.

It is one person's tooling, run unattended from `cron`, against their own
accounts and their own files. It is not a service, and there is no notion of a
second user.

The project began in February 2012 and this is the first release since 2015. The
core, the Recipe format and the plugin contract are unchanged; what has changed
is that it runs on a current Ruby, installs from a current RubyGems, and ships
a plugin set every part of which still has somewhere to talk to. See
[`doc/VERSIONS`](doc/VERSIONS).

## 2. Features

- **Recipes in YAML.** A job is a file, not a program. No Ruby is written to
  wire a pipeline together.
- **34 plugins** across seven categories: subscribe, custom feed, filter,
  store, provide, notify, publish — and every one of them has a current use.
- **Markdown out of the box.** `PublishMarkdown` writes the result as a plain
  Markdown document, to a file or to standard output, with no service and no
  credential behind it. It is the natural end of a new Recipe.
- **Plugins are found, not registered.** Adding one is dropping a file in a
  directory. No framework file is edited.
- **Your plugins override the shipped ones.** `~/.automatic/plugins` is searched
  first, so a shipped plugin can be replaced without touching the installation.
- **De-duplication built in.** The store plugins keep a SQLite record of what
  has been seen, which is what makes a Recipe safe to run every hour. Their
  gems are installed when you use them, not before.
- **Retry and interval** on everything that reaches the network, configured per
  plugin in the Recipe.
- **A small installation.** A gem needed by one plugin is not a dependency of
  the framework: `gem install automatic` brings four pure-Ruby gems and the
  command, and installs neither an HTML parser nor a database — let alone an
  AWS SDK.
- **No museum.** Every plugin is classified, with its reason, in
  [`doc/PLUGINS.md`](doc/PLUGINS.md). Nothing dead is stubbed into looking
  alive, and an integration whose service has gone is removed rather than
  kept as a fossil.

## 3. Architecture

```text
bin/automatic                 process entry point; exit status only
        |
        v
Automatic::CLI                options, subcommands, error reporting
        |
        v
Automatic  ->  Recipe  ->  Pipeline  ->  Automatic::Plugin::*
        |                                       |
        v                                       v
Automatic::Log            Automatic::FeedMaker / FeedParser
```

One run is: load the Recipe, then for each plugin entry in order, load the
class, construct it with its settings and the current pipeline, call `run`, and
take the result as the input to the next.

```ruby
pipeline = []
recipe.each_plugin do |plugin|
  mod = plugin.module
  load_plugin(mod)
  klass = Automatic::Plugin.const_get(mod)
  pipeline = klass.new(plugin.config, pipeline).run
end
```

That is the whole of the framework's behaviour. The value passed along — the
*pipeline* — is an array of feed objects, and because every plugin takes and
returns that one shape, any plugin composes with any other.

The pipeline normally **narrows**: subscription plugins produce, filters and
stores reduce, publishers consume. Reading a Recipe top to bottom reads the
data flow.

The full account is [`doc/BASIC_DESIGN.md`](doc/BASIC_DESIGN.md).

## 4. Supported environment

- **Ruby 3.3 through 4.0.** CI validates 3.3, 3.4 and 4.0.
- A Unix-like system. GNU/Linux and macOS are what it is used on. Windows is not
  supported.
- A compiler only if you install an optional plugin gem that builds from source
  on your platform, such as `nokogiri` or `sqlite3`. The framework's own
  dependencies are pure Ruby.

Ruby 3.3 is the floor: it is the oldest maintained release the dependencies are
resolved and tested against. Nothing older is tested or supported.

Two statements, and they are not the same one:

- **Supported range.** The code is written for Ruby 3.3 through 4.0, using APIs
  the whole range shares. `required_ruby_version` is `>= 3.3.0` and has no upper
  bound, so a Ruby newer than the matrix is permitted rather than refused.
- **Continuously validated versions.** CI runs the ends of the range and the
  release in the middle — 3.3, 3.4 and 4.0 — rather than every intermediate
  release. A version's absence from the matrix means it is not verified on every
  commit; it does not mean it is expected to fail.

## 5. Installation

### From RubyGems

```sh
gem install automatic
automatic --version
```

That installs the framework, the command and four pure-Ruby dependencies.
A gem that only one plugin needs is not among them: install it when you use
that plugin, with `gem install nokogiri` or `gem install activerecord sqlite3`.
[`doc/DEPLOYMENT.md`](doc/DEPLOYMENT.md) lists which plugin needs which.

### From a checkout

Use a checkout to try the current development version, change the source,
develop a plugin or verify changes before a release. There are three ways to
set one up; start with the first.

```sh
git clone https://github.com/id774/automaticruby.git
cd automaticruby

# Minimal: the framework and its test suite. No optional plugin gem.
bundle install

# All supported optional plugin dependencies, for plugin work.
bundle config set --local with plugins
bundle install

# Or start minimal and add one group at a time, as you use its plugins.
bundle config set --local with store
bundle install
```

```sh
bundle exec bin/automatic --version
bundle exec rake
```

A plain `bundle install` resolves the runtime dependencies declared by
`automatic.gemspec` and the development ones, and installs no optional plugin
gem: those are optional Bundler groups, which are installed only when asked
for. If the `bundle` command is unavailable, install Bundler first with
`gem install bundler`.

In a checkout, every `automatic` below becomes `bundle exec bin/automatic`, and
`bundle exec` sees only the bundle — so a plugin's gem is added with a group
rather than with `gem install`. The group names, and which plugin needs which
gem, are in [`doc/DEPLOYMENT.md`](doc/DEPLOYMENT.md); what each plugin does is
in [`doc/PLUGINS.md`](doc/PLUGINS.md).

## 6. Quick start

The complete first-run guide is [`doc/QUICKSTART.md`](doc/QUICKSTART.md).

```sh
automatic scaffold
automatic -c ~/.automatic/config/example/feed2markdown.yml
```

`scaffold` creates `~/.automatic` with `config/`, `plugins/`, `db/` and
`assets/`, and copies the example Recipes into `~/.automatic/config/example`.
It never overwrites anything already there.

That Recipe fetches the public Ruby news feed and appends its items to
`~/.automatic/markdown/feeds.md`, using nothing but the framework and what
`gem install automatic` brought. Read the file, `grep` it, put it in a
repository, or hand it to whatever reads text next. `feed2console.yml` beside
it is the same pipeline printing to the terminal. Adding a store plugin, so
that a second run appends only what is new, is step 5 of the Quick Start and
the point at which the first optional gems are installed.

To check the framework without any network, write this instead:

```yaml
# ~/.automatic/config/selftest.yml
plugins:
  - module: SubscriptionText
    config:
      feeds:
        - title: hello
          url: https://example.com/
  - module: PublishMarkdown
```

```sh
automatic -c selftest.yml
```

A bare name is resolved inside `~/.automatic/config`, which is why that command
has no path in it. Anything with a `/` is used as a path as given.

Installing, scheduling and operating it is [`doc/DEPLOYMENT.md`](doc/DEPLOYMENT.md).

## 7. Recipes

A Recipe is one job: which plugins run, in what order, with what settings.

```yaml
global:                       # optional
  log:
    level: info               # info | warn | error | none

plugins:                      # required
  - module: SubscriptionFeed  # required: the plugin class name
    config:                   # optional: passed to that plugin only
      feeds:
        - https://example.com/feed
      retry: 3
      interval: 5

  - module: PublishConsole    # a plugin needing no settings omits config
```

- Entries run **in the order written**, each receiving the previous one's
  output.
- `config` is handed to the plugin untouched. The framework does not validate
  it and does not know what any key means.
- A `module` that resolves to nothing fails **before any plugin runs**, so a
  typo costs nothing.
- `global.log.level` is the only framework setting. `global.timezone` and
  `global.cache` appear in old Recipes and are read by nothing.

Two conventions worth knowing before writing one:

- **Put a store plugin in front of anything with an effect.** `StorePermalink`
  records what has been seen and passes on only what has not. It is what makes a
  Recipe safe to run every hour instead of once.
- **Set `interval` on anything that fetches repeatedly**, in seconds. Scraping
  politely is a requirement of this project, not a courtesy.

The full specification — every key, every failure mode, the type conventions,
and the compatibility promise — is [`doc/PLUGINS.md`](doc/PLUGINS.md) section 2.

## 8. Plugins

A plugin is a class in `Automatic::Plugin`, built with two arguments, answering
one method:

```ruby
module Automatic::Plugin
  class FilterShortTitle
    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @max      = (@config['max_length'] || 40).to_i
    end

    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil?

        kept = feeds.items.select { |item| item.title.to_s.length <= @max }
        returned << Automatic::FeedMaker.create_pipeline(kept) unless kept.empty?
      end
    end
  end
end
```

Save it as `~/.automatic/plugins/filter/short_title.rb` and a Recipe can name
`FilterShortTitle`. Nothing was registered: the class name and the file path are
the same fact written twice, and the loader converts between them.

For a smaller complete example, including testing guidance, see
[`doc/PLUGIN_DEVELOPMENT.md`](doc/PLUGIN_DEVELOPMENT.md).

| Category | Directory | Role |
| --- | --- | --- |
| `Subscription` | `subscription/` | Acquire from outside |
| `CustomFeed` | `custom_feed/` | Build a feed from a source that is not one |
| `Filter` | `filter/` | Select, reorder, rewrite |
| `Store` | `store/` | Persist, and drop what was seen before |
| `Provide` | `provide/` | Emit the payload elsewhere |
| `Notify` | `notify/` | Send a notification |
| `Publish` | `publish/` | Send the result out, print it, or write it as a document |

`~/.automatic/plugins` is searched **before** the installation, so a file named
like a shipped plugin replaces it.

### Which plugins still work

34 plugins ship with the gem. Every one is classified in
[`doc/PLUGINS.md`](doc/PLUGINS.md) section 6, with its settings and the reason
for its status:

| Status | Count | Meaning |
| --- | --- | --- |
| **Supported** | 23 | Works on the supported Rubies with current dependencies |
| **Supported (external)** | 10 | Works, but needs something you provide: a service, a command, a credential, a data file |
| **Needs rework** | 1 | The service exists; this plugin speaks a replaced interface |

Eleven plugins were removed in this release rather than kept as history: each
talked to a service that has shut down, or through an API that has been
withdrawn with no replacement. They are listed with their reasons in
[`doc/PLUGINS.md`](doc/PLUGINS.md) section 8, and Git history holds the code.
A Recipe naming one of them now fails at load, before anything runs.

Restoring the one in **Needs rework** — `PublishHatenaBookmark` — is
self-contained work and a good first contribution.

No plugin here is stubbed, mocked or simulated to make a test pass. Where a
plugin's gem is not installed its spec is skipped and says which gem is
missing; where the plugin still loads, its spec covers what does not need the
service. A dead integration is never made to look alive — it is removed.

The contract, a worked example, and how to test a plugin are in
[`doc/PLUGINS.md`](doc/PLUGINS.md) sections 3 and 4.

## 9. CLI usage

```sh
automatic -c RECIPE          # run a Recipe
automatic SUBCOMMAND [ARGS]  # run an auxiliary tool
automatic --help
automatic --version
```

### Options

| Option | Meaning |
| --- | --- |
| `-c`, `--config FILE` | The Recipe to run. A bare name is looked for in `~/.automatic/config`. |
| `-h`, `--help` | Print usage and exit `0`. |
| `-v`, `--version` | Print the version and exit `0`. |

### Subcommands

| Subcommand | What it does |
| --- | --- |
| `scaffold` | Create `~/.automatic` and its subdirectories. Overwrites nothing. |
| `unscaffold` | Remove `~/.automatic` entirely, **including your Recipes and databases**. |
| `autodiscovery <url>` | Print the feed URLs a page advertises. |
| `feedparser <url>` | Parse a feed and print the result. |
| `inspect <url>` | Discover a page's feeds, then parse the first. |
| `opmlparser <path>` | Print the feed URLs in an OPML file. |
| `log <level> <message>` | Emit one line in the framework's log format. |

The middle five answer "will this work as a Recipe input?" before you write the
Recipe:

```sh
automatic autodiscovery https://example.com/
automatic inspect https://example.com/
automatic opmlparser subscriptions.opml > feeds.txt
```

### Exit status

| Status | Meaning |
| --- | --- |
| `0` | The Recipe ran, the subcommand did its work, or help or version was printed |
| `1` | The run or the subcommand failed, or nothing was asked for |
| `2` | The command line was rejected |

A `cron` entry can rely on these.

## 10. Configuration

There is no configuration file besides the Recipe. Every setting a job needs is
in the Recipe that defines the job, which is what makes a Recipe portable
between machines.

**Framework settings** — one, `global.log.level`, with the values `info`,
`warn`, `error` and `none`.

**Plugin settings** — the `config` mapping of a plugin entry, passed to that
plugin and read by nothing else. Established names: `retry` for an attempt
count, `interval` for seconds between attempts, `db` for a database file,
`path` for a directory.

**Credentials** are plugin settings, which makes a Recipe holding one a secret
file:

```sh
chmod 600 ~/.automatic/config/publish.yml
```

Nothing encrypts it and nothing keeps it elsewhere. Keep credentials in their
own Recipe, and never commit one. This is a weakness inherited from the original
design and is recorded as one in
[`doc/REQUIREMENTS.md`](doc/REQUIREMENTS.md) section 17.

**A Recipe is trusted local configuration.** It names Ruby classes and the
framework runs them, so anyone who can write a Recipe — or a file under
`~/.automatic/plugins` — can run code as you. Do not run a Recipe from a source
you do not trust. (Recipes are parsed with `YAML.safe_load` so that the document
itself cannot instantiate arbitrary Ruby classes, but that is a second line of
defence, not the boundary.)

## 11. The user directory

`~/.automatic` holds what is yours, so that it survives reinstalling the gem.

| Path | Holds |
| --- | --- |
| `~/.automatic/config` | Your Recipes. A bare `-c` name is resolved here. |
| `~/.automatic/plugins` | Your plugins, in category subdirectories. Searched first. |
| `~/.automatic/db` | SQLite databases the store plugins write. |
| `~/.automatic/assets` | Data files plugins read, such as the fulltext siteinfo. |

Each part is optional; where one is absent, the corresponding directory inside
the installation is used instead. `automatic scaffold` creates and seeds them
and overwrites nothing, so it is safe to run after an upgrade.

## 12. Testing

```sh
bundle exec rake             # the whole suite
bundle exec rake spec:lib    # the framework only
bundle exec rake spec:plugins
COVERAGE=on bundle exec rake spec
```

- **The suite reaches no network and needs no credential.** That is a rule, not
  a coincidence, and CI configures no secret.
- Specs mirror the source tree: `spec/lib/` for the framework,
  `spec/plugins/<category>/` for plugins.
- Examples tagged `:network` reach real hosts and are **excluded by default**.
  Several point at hosts that no longer serve what they expect, which is why
  they are not a gate. Run them deliberately:

  ```sh
  AUTOMATIC_NETWORK_SPECS=1 bundle exec rake spec
  ```

- A plugin whose gem the Gemfile declares in an optional group is **not
  verified by the default suite**, because no optional group is installed.
  Install them to run those specs as part of the ordinary suite:

  ```sh
  bundle config set --local with plugins
  bundle install
  bundle exec rake
  ```

- A spec whose plugin needs a gem that is not installed is skipped, and says
  which gem is missing. That absence is the signal; a plugin whose service no
  longer exists is never stubbed into passing.
- `test/integration/` holds Recipes for exercising plugins against real
  services. They are run by hand, are not part of the suite, and are never run
  in CI. Most need a credential or a service you run — read one before
  running it.

The required check installs the bundle, builds the gem, loads the library, runs
the CLI and runs the default suite on each validated Ruby version, from
[`.github/workflows/ci.yml`](.github/workflows/ci.yml). It configures no secret
and installs no optional plugin gem, so no plugin's own dependency is a
condition of a change being merged — and what it proves on every commit is that
the framework needs nothing but its own runtime dependencies. A separate,
non-required workflow,
[`.github/workflows/plugins.yml`](.github/workflows/plugins.yml), installs the
`plugins` group and runs the same suite, which is how the all-plugins setup is
checked.

## 13. Development

```sh
git clone https://github.com/id774/automaticruby.git
cd automaticruby
bundle install
bundle exec rake
bundle exec bin/automatic -c config/feed2console.yml
```

Contributions are welcome — a new plugin, or reviving the one that needs
rework, most of all.

1. Fork the repository.
2. Write the change, with a spec that reaches no network.
3. Update the documents in the same commit. A behaviour change with no
   documentation change is not finished.
4. Send a pull request.

Read [`doc/POLICY.md`](doc/POLICY.md) first. It states the rules a change is
judged by: the direction of dependency, where a new capability belongs, how
dependencies are added, how the documents divide, and how a version history
entry is written.

Two rules worth knowing before you start:

- **A gem needed by one plugin is not a dependency of the framework.** Require
  it at the top of the plugin's own file.
- **Nothing dead is faked.** A plugin whose service has shut down is removed,
  not stubbed into passing a test.

- Repository: <https://github.com/id774/automaticruby>
- Issues: <https://github.com/id774/automaticruby/issues>
- RubyGems: <https://rubygems.org/gems/automatic>

## 14. Repository structure

```text
.
├── bin/automatic            The executable. A process entry point and nothing else.
├── lib/
│   ├── automatic.rb         The module: directories, and run
│   └── automatic/
│       ├── cli.rb           Options and subcommands; returns an exit status
│       ├── recipe.rb        Loads and validates a Recipe
│       ├── pipeline.rb      Finds plugins by name and runs them in order
│       ├── log.rb           Levelled logging to standard output
│       ├── feed_maker.rb    Builds pipeline values from plain data
│       ├── feed_parser.rb   Fetches and parses feeds
│       ├── http.rb          The one way in for what plugins fetch
│       ├── opml.rb          OPML parser, for the opmlparser subcommand
│       ├── environment.rb   Bundler setup for a source checkout
│       └── version.rb
├── plugins/                 The shipped plugins, one directory per category
│   ├── subscription/        Acquire from outside
│   ├── custom_feed/         Build a feed from a source that is not one
│   ├── filter/              Select, reorder, rewrite
│   ├── store/               Persist, and drop what was seen before
│   ├── provide/             Emit the payload elsewhere
│   ├── notify/              Send a notification
│   └── publish/             Send the result out, print it, or write it as a document
├── config/                  Example Recipes; scaffold copies these out
├── assets/siteinfo/         Data files plugins read
├── db/                      Fallback for SQLite files when ~/.automatic/db is absent
├── spec/                    RSpec suite, mirroring lib/ and plugins/
├── test/
│   ├── fixtures/            Fixtures for the manual tests
│   └── integration/         Recipes run by hand against real services
├── script/build             Runs what CI runs, plus the integration recipes
├── vendor/                  Legacy placeholder; the normal setup does not install gems here
├── doc/                     See below
├── automatic.gemspec        Hand-maintained
├── Gemfile
├── Rakefile
└── VERSION
```

## 15. Documents

Everything needed to understand, build, run and change this repository is in
this repository. No document here defers to another repository.

| Document | What it holds |
| --- | --- |
| [`doc/QUICKSTART.md`](doc/QUICKSTART.md) | The shortest path from installation to a Markdown result |
| [`doc/PLUGIN_DEVELOPMENT.md`](doc/PLUGIN_DEVELOPMENT.md) | A complete user plugin and practical testing guidance |
| [`doc/REQUIREMENTS.md`](doc/REQUIREMENTS.md) | What the system is for, what it guarantees, where its responsibility ends |
| [`doc/BASIC_DESIGN.md`](doc/BASIC_DESIGN.md) | How it is composed: the parts, their responsibilities, the flow of a run |
| [`doc/PLUGINS.md`](doc/PLUGINS.md) | The Recipe format, the plugin contract, and the catalogue of every shipped plugin |
| [`doc/POLICY.md`](doc/POLICY.md) | How a change is made and judged: style, dependencies, tests, versioning |
| [`doc/DEPLOYMENT.md`](doc/DEPLOYMENT.md) | Installing, scheduling, operating, and what to do when it fails |
| [`doc/RELEASING.md`](doc/RELEASING.md) | For maintainers: building, verifying and publishing the gem |
| [`doc/VERSIONS`](doc/VERSIONS) | The release history, from 2012 |
| [`doc/LICENSE.md`](doc/LICENSE.md) | The licence |
| [`doc/COPYING`](doc/COPYING) | The GPLv3 text |
| [`doc/COPYING.LESSER`](doc/COPYING.LESSER) | The LGPLv3 text |
| [`doc/AUTHORS`](doc/AUTHORS) | Contributors |

## 16. Versioning

Releases are numbered `<year>.<month>`, two digits each, taken from the release
date. The scheme mimics Ubuntu's and has been used since the first release in
February 2012.

```text
26.08      a release made in August 2026
26.08.1    a release correcting 26.08 in the same month
```

The number carries no compatibility meaning: a month is not a major version. A
change that affects an existing Recipe is stated as such in its
[`doc/VERSIONS`](doc/VERSIONS) entry.

What this repository promises not to break — the Recipe format, the plugin
contract, the plugin naming rule, the user directory, the CLI, and existing
store databases — is listed in [`doc/POLICY.md`](doc/POLICY.md) section 7.

## 17. License

Automatic Ruby is dual-licensed under the
[GNU General Public License, Version 3](https://www.gnu.org/licenses/gpl-3.0.html)
or the
[GNU Lesser General Public License, Version 3](https://www.gnu.org/licenses/lgpl-3.0.html).
You may choose either license at your discretion.

See [`doc/LICENSE.md`](doc/LICENSE.md), [`doc/COPYING`](doc/COPYING) and
[`doc/COPYING.LESSER`](doc/COPYING.LESSER) for the full license texts.

Copyright (c) 2012-2026 Automatic Ruby Developers.

Project created by [id774](http://id774.net). Contributors are listed in
[`doc/AUTHORS`](doc/AUTHORS).
