# Deployment

How to install Automatic Ruby, set up a user directory, write and verify a
Recipe, put it in `cron`, and operate it afterwards.

What the system is belongs to [`REQUIREMENTS.md`](REQUIREMENTS.md); how a Recipe
is written belongs to [`PLUGINS.md`](PLUGINS.md). This document assumes you have
read neither and points at them where they are needed.

It stands on its own. Nothing in it is completed by a document kept in another
repository.

## What this touches, and what it does not

Installing and running Automatic Ruby affects:

- the RubyGems installation you install into, or a checkout directory,
- `~/.automatic`, the user directory, and nothing else under your home
  directory,
- whatever a Recipe of yours tells a plugin to write: files under a path you
  name, rows in a SQLite database you name, requests to services you configure.

It does not install a service, does not write outside those places, does not
require root, and does not run as a daemon. There is nothing to start and
nothing to stop.

## Before you begin

- A Unix-like system. GNU/Linux and macOS are what this is used on; Windows is
  not supported.
- **Ruby 3.3 through 4.0.** Check with `ruby -v`. CI validates 3.3, 3.4 and 4.0;
  a version between them is supported and is simply not checked on every commit,
  and a Ruby newer than 4.0 is permitted rather than refused. See
  [`REQUIREMENTS.md`](REQUIREMENTS.md) section 20.
- A build environment for native extensions, because `nokogiri` and `sqlite3`
  may build from source:

  ```sh
  # Debian or Ubuntu
  sudo apt install build-essential ruby-dev libsqlite3-dev

  # macOS, with the Xcode command line tools installed
  xcode-select --install
  ```

- Optional gems for particular plugins, listed in the table under
  "Optional plugin dependencies" below. None is needed to install or to run a
  Recipe that does not use the plugin.

## Install

### From RubyGems

```sh
gem install automatic
automatic --version
```

That installs the framework, its runtime dependencies and the `automatic`
command.

### From a checkout

For working on the framework, or for running a version that is not released:

```sh
git clone https://github.com/id774/automaticruby.git
cd automaticruby
bundle install
bundle exec bin/automatic --version
```

`bundle install` installs into your default gem path. To keep it inside the
checkout instead:

```sh
bundle config set --local path vendor/bundle
bundle install
```

Everything below that says `automatic` becomes `bundle exec bin/automatic` in a
checkout.

## Create the user directory

```sh
automatic scaffold
```

This creates `~/.automatic` and seeds it:

```text
~/.automatic/
├── config/            your Recipes
│   └── example/       the Recipes shipped with the gem, copied here
├── plugins/           your own plugins, in category subdirectories
├── db/                SQLite databases the store plugins write
└── assets/            data files plugins read
    └── siteinfo/
```

It creates only what is missing, so running it again after an upgrade is safe
and will not overwrite a Recipe.

`automatic unscaffold` removes the whole directory — **including your Recipes
and your databases**. It is not an undo for `scaffold`.

The directory is optional. Where a part of it is absent the framework falls back
to the corresponding directory inside the installation, so a Recipe given by
full path runs without it.

## Verify the installation

```sh
automatic -c ~/.automatic/config/example/feed2console.yml
```

That fetches one feed and prints its items. Two things can go wrong and both are
worth telling apart:

- A message about the feed being unreachable means the network or that
  particular feed, not the installation.
- A Ruby `LoadError` naming a gem means the installation.

To check the framework without any network at all, write a Recipe that uses
`SubscriptionText`:

```yaml
# ~/.automatic/config/selftest.yml
global:
  log:
    level: info

plugins:
  - module: SubscriptionText
    config:
      feeds:
        - title: hello
          url: https://example.com/
  - module: PublishConsoleLink
```

```sh
automatic -c selftest.yml
```

A bare name is resolved inside `~/.automatic/config`, which is why that command
has no path in it.

## Write a Recipe

A Recipe is one job: the plugins it runs, in order, with their settings. The
format is specified in [`PLUGINS.md`](PLUGINS.md) section 2 and the plugins are
catalogued in section 6. A worked example, to save a blog's images:

```yaml
# ~/.automatic/config/images.yml
global:
  log:
    level: info

plugins:
  - module: SubscriptionFeed
    config:
      feeds:
        - https://example.com/feed
      retry: 3
      interval: 5

  - module: FilterImageSource

  - module: StorePermalink
    config:
      db: images.db

  - module: StoreFile
    config:
      path: /var/tmp/automatic/images
      retry: 2
      interval: 3
```

Three things in that Recipe are the operational advice of this document:

- **`StorePermalink` before the plugin with the effect.** It records what has
  been seen and passes on only what has not, which is what makes the Recipe safe
  to run every hour. Without it, every run downloads everything again.
- **`interval` on anything that fetches repeatedly.** It is the pause between
  requests, in seconds. Set it whenever a plugin will make more than a handful
  of requests to one host.
- **`retry` on anything that reaches the network.** A transient failure retries
  rather than ending the run.

### Verify it before scheduling it

Run it by hand, more than once:

```sh
automatic -c images.yml
echo "exit status: $?"
automatic -c images.yml     # the second run should do much less
```

The second run doing nothing is the store plugin working. If it does everything
again, the Recipe has no store plugin, or the database it names is not being
written where you think.

To see what a Recipe produces without any effect, replace the last plugin with
`PublishConsole` — which prints each item in full — or `PublishConsoleLink`,
which prints only links.

Diagnostic subcommands for the input end:

```sh
automatic autodiscovery https://example.com/     # what feeds does this page advertise
automatic feedparser https://example.com/feed    # does that feed parse
automatic inspect https://example.com/           # both, in one step
automatic opmlparser subscriptions.opml          # the feed URLs in an OPML export
```

## Publishing to a Markdown document

A Recipe that ends in `PublishMarkdown` leaves what it collected as a Markdown
file, with no service and no credential involved. The plugin's specification —
what it writes for each field, and what it does with HTML in a body — is
[`PLUGINS.md`](PLUGINS.md) section 6.7. What matters when running it
unattended is below.

```yaml
  - module: StorePermalink
    config:
      db: feeds.db

  - module: PublishMarkdown
    config:
      file: ~/notes/feeds.md
      mode: append
```

**The output path.** `file` is expanded, so `~` works, and a relative path is
resolved against the process's working directory — which under `cron` is your
home directory and is not worth relying on. Use an absolute path or a `~` path.
A missing parent directory is created; nothing else on the path is touched, and
the plugin writes to no other file.

**Append or overwrite.** `mode: append`, the default, adds the run's items to
the end of the file, which is what a Recipe in `cron` wants: with a store plugin
in front of it, each run contributes only what is new and the file becomes a
journal. `mode: overwrite` replaces the file, for a Recipe whose output is meant
to be the current state rather than a history — a digest regenerated every
morning, say. In either mode a run that produces no items writes nothing at all:
the file is not created, not appended to and not truncated, so a quiet run
leaves yesterday's document intact.

**Permissions.** The file is created with your umask, like any other file the
process writes. The plugin does not adjust it. Where the collected material is
private, put the document in a directory you have restricted rather than relying
on the file's own mode:

```sh
mkdir -p ~/notes && chmod 700 ~/notes
```

**Keeping the document clean.** With no `file`, the document goes to standard
output — and so does the log ([`REQUIREMENTS.md`](REQUIREMENTS.md) section 14),
so a redirect that collects one collects the other. Two ways out, and the Recipe
chooses:

```yaml
global:
  log:
    level: none         # standard output then carries the document alone
```

```sh
automatic -c feeds.yml > today.md
```

or give the plugin a `file`, which leaves standard output to the log and is what
a `cron` entry wants, since the log is what you have afterwards when something
went wrong:

```crontab
  0 7 * * *  /usr/local/bin/automatic -c $HOME/.automatic/config/feeds.yml >> $HOME/.automatic/log/feeds.log 2>&1
```

Redirecting the document itself from `cron` works as well, and then the log
needs somewhere else to go:

```crontab
  0 7 * * *  /usr/local/bin/automatic -c $HOME/.automatic/config/feeds.yml >> $HOME/notes/feeds.md 2>>$HOME/.automatic/log/feeds.log
```

That entry is only clean if the Recipe sets `log.level: none`; otherwise the log
lines land in the document. Setting the level in the Recipe is the supported
way to do this, and the framework has no separate switch for it.

**Afterwards.** The file is ordinary text: read it, `grep` it, feed it to
another program, or keep it in a Git repository and commit after each run. The
plugin writes nothing that changes between runs of the same pipeline, so a
commit shows what arrived and nothing else.

## Credentials

Plugins that reach an authenticated service take their credentials as ordinary
Recipe settings. **A Recipe holding a credential is a secret file**, and nothing
in the framework encrypts it or keeps it elsewhere:

```sh
chmod 600 ~/.automatic/config/publish.yml
```

Rules worth holding to:

- Keep credentials in their own Recipe rather than spread across several.
- Never commit a Recipe holding one, to this repository or to your own.
- The framework never logs a setting, and no plugin should log one. If you see a
  credential in a log, that is a defect worth reporting.

This is a weakness inherited from the original design rather than a decision
made now; it is recorded in [`REQUIREMENTS.md`](REQUIREMENTS.md) section 17.

## Schedule it

Automatic Ruby has no scheduler. One invocation runs one Recipe once and exits,
and `cron` decides when.

```crontab
# m h  dom mon dow  command
  0 *   *   *   *   /usr/local/bin/automatic -c $HOME/.automatic/config/images.yml >> $HOME/.automatic/log/images.log 2>&1
```

```sh
mkdir -p ~/.automatic/log
```

Points that matter in an unattended run:

- **Use an absolute path to the command.** `cron` has a short `PATH`. `command
  -v automatic` gives you the path; in a checkout it is `bundle exec` from the
  checkout directory, so use a small wrapper script rather than a long `cron`
  line.
- **Capture both streams.** `2>&1` matters: the log goes to standard output and
  errors go to standard error.
- **There is no locking.** A run that takes longer than its interval will
  overlap with the next one. Either schedule with headroom, or wrap the command
  in `flock`:

  ```crontab
  0 * * * * /usr/bin/flock -n /tmp/automatic-images.lock /usr/local/bin/automatic -c $HOME/.automatic/config/images.yml >> $HOME/.automatic/log/images.log 2>&1
  ```

- **Mind the service at the other end.** A Recipe reaching a rate-limited API is
  scheduled with that limit in mind, and `interval` is set within the run.
- **The exit status is meaningful**: `0` the Recipe ran, `1` it failed, `2` the
  command line was wrong. A monitoring system can use it.

## Reading the log

One line per event, on standard output, through Ruby's `Logger`. The level is
set per Recipe:

```yaml
global:
  log:
    level: info      # info | warn | error | none
```

- `info` — what each step did: the Recipe loaded, the feed parsed, the database
  opened, the item stored. Verbose, and what you want while a Recipe is new.
- `warn` — what was skipped: an item missing a field, a save that failed.
- `error` — what failed: a fetch that exhausted its retries.
- `none` — nothing.

Once a Recipe is settled, `warn` keeps the log to what needs reading. Rotate the
file yourself; the framework does not.

## Upgrading

```sh
gem update automatic
automatic --version
automatic scaffold          # adds anything new; overwrites nothing
```

Then run each Recipe by hand once before trusting the schedule again. Your
Recipes and databases are in `~/.automatic` and are untouched by a gem upgrade.

Read [`VERSIONS`](VERSIONS) for what changed. A change that affects an existing
Recipe is stated there in terms you can act on.

## Optional plugin dependencies

These gems are not installed with the framework. Install one only if you use the
plugin, and check its status in [`PLUGINS.md`](PLUGINS.md) section 6 first —
several of these plugins talk to services that no longer exist.

| Plugin | Needs | Status |
| --- | --- | --- |
| `FilterSanitize` | `sanitize` | Supported |
| `FilterDescriptionLink` | `nkf` | Supported |
| `CustomFeedSVNLog` | `xml-simple`, and the `svn` command | Supported (external) |
| `ProvideFluentd`, `PublishFluentd` | `fluent-logger`, and a Fluentd instance | Supported (external) |
| `PublishMemcached` | `dalli`, and a memcached server | Supported (external) |
| `PublishEject` | the `eject` or `drutil` command | Supported (external) |
| `NotifyIkachan` | an `ikachan` gateway you run | Supported (external) |
| `StoreFile`, S3 path only | the `aws-sdk` v1 interface | Needs rework |
| `PublishAmazonS3` | the `aws-sdk` v1 interface | Needs rework |
| `PublishTwitter`, `SubscriptionTwitterSearch` | — | Unsupported |
| `PublishPocket`, `SubscriptionPocket` | — | Unsupported |
| `PublishHipchat` | — | Unsupported |
| `PublishGoogleCalendar` | — | Unsupported |
| `SubscriptionWeather` | — | Unsupported |

```sh
gem install sanitize             # for FilterSanitize
gem install nkf                  # for FilterDescriptionLink
gem install fluent-logger        # for the Fluentd plugins
gem install dalli                # for PublishMemcached
gem install xml-simple           # for CustomFeedSVNLog
```

The two AWS rows are listed for completeness rather than as instructions.
They call `AWS::S3`, which AWS SDK for Ruby version 1 provided and the current
`aws-sdk-s3` does not; installing a gem will not make them work, and the plugins
need rework. `StoreFile` makes that requirement lazily, so its ordinary HTTP
download path works with no AWS gem installed at all.

In a checkout, install the `Gemfile`'s optional `plugins` group instead —
uncommenting the entry first, where the gem is one of the commented ones:

```sh
BUNDLE_WITH=plugins bundle install
```

That group is not installed by default and is not installed in CI, so these
plugins are outside what the default test suite verifies. Installing it also
brings their specs into the ordinary `bundle exec rake` run.

## Your own plugins

`~/.automatic/plugins` is on the loader's search path, **ahead of the
installation**, so a plugin you put there is found first and a file named like a
shipped plugin replaces it. Overriding a shipped plugin without editing the
installation is the intended use.

```sh
$EDITOR ~/.automatic/plugins/filter/my_filter.rb
```

The class is `Automatic::Plugin::FilterMyFilter`; the contract and a worked
example are in [`PLUGINS.md`](PLUGINS.md) sections 3 and 4. A gem upgrade does
not touch this directory.

## When something fails

**`command not found: automatic`** — the gem's binary directory is not on
`PATH`. `gem environment` prints it as EXECUTABLE DIRECTORY.

**`LoadError: cannot load such file -- <gem>`** — a plugin's optional dependency
is missing. The message names it; install it, or check the table above in case
the plugin is one that no longer works.

**`unknown plugin named X`** — the Recipe names a module the loader cannot
resolve. Check the spelling against [`PLUGINS.md`](PLUGINS.md) section 6, and
check the class-name-to-path rule in section 3.2 if it is your own plugin — a
file in the wrong category directory is never found.

**A Recipe path is not found** — a bare name is looked for in
`~/.automatic/config` only. Use a path with a `/` in it for anything else.

**The run stops partway** — a plugin raised, and the framework does not catch
plugin exceptions. Everything before it has already happened; there is no
rollback. Rerun after fixing the cause. If the plugins after the failure must
not repeat their effect, that is what a store plugin in front of them is for.

**A run repeats work it did last time** — the Recipe has no store plugin, or the
database it names is not where you think. Check the `Using Database:` line in
an `info`-level log.

**Nothing is published, but nothing failed either** — a filter dropped
everything, or the store plugin had already seen it all. Insert
`PublishConsoleLink` between steps to see what the pipeline holds where.

**A plugin behaves as though its settings are absent** — settings are read by
string key, and a typo in a key is silently `nil`. Check the key names against
the plugin's table in `PLUGINS.md` section 6.

## Running the integration recipes

`test/integration/` holds Recipes used to exercise plugins against real
services. They are run by hand, they are not part of the test suite, and they
are not run in CI:

```sh
bundle exec bin/automatic -c test/integration/test_sort.yml
```

Most of them need a credential, a service that no longer exists, or both. Read
the Recipe before running it, and check the plugin's status in
[`PLUGINS.md`](PLUGINS.md) section 6.

## Uninstalling

```sh
gem uninstall automatic
rm -rf ~/.automatic          # or: automatic unscaffold, before uninstalling
```

Files that Recipes wrote outside `~/.automatic` — downloads under a `path` you
configured, for instance — are yours to remove.
