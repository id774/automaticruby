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
- Optional gems for particular plugins, listed in the table under
  "Optional plugin dependencies" below. None is needed to install Automatic
  Ruby, or to run a Recipe that does not use the plugin; a Recipe that does
  name one installs it as a step of its own, which is what the Quick Start's
  step 4 is.
- A build environment may be needed for one of those optional gems — `nokogiri`
  and `sqlite3` build a native extension where no binary package matches your
  platform. The framework's own dependencies are pure Ruby, so the normal
  installation needs no build tools; install them only if installing an
  optional gem reports that they are required.

## Install

### From RubyGems

```sh
gem install automatic
automatic --version
```

That installs the framework, the `automatic` command and four pure-Ruby
runtime dependencies: `activesupport`, `hashie`, `rexml` and `rss`. That is the
whole of it. No HTML parser, no database, no service client — a gem needed by
one plugin is installed by the operator who uses that plugin, so installing
Automatic Ruby does not install what your Recipes do not use.

Add one when you use the plugin that needs it:

```sh
gem install nokogiri              # the plugins that read HTML
gem install activerecord sqlite3  # the store plugins
```

The table under "Optional plugin dependencies" below says which plugin needs
which, and is the list to check before adding anything.

### From a checkout

For working on the framework, or for running a version that is not released.
There are three ways to set one up, and the first is the one to start with.

**Minimal — the framework and its test suite.** What you want for running the
checkout, and for developing the framework itself:

```sh
git clone https://github.com/id774/automaticruby.git
cd automaticruby
bundle install
bundle exec bin/automatic --version
bundle exec rake
```

`bundle install` resolves the runtime dependencies of `automatic.gemspec` and
the development ones — `rake`, `rspec` and `simplecov`. It installs **no**
optional plugin gem: the `Gemfile`'s groups for those are optional, and Bundler
does not install an optional group unless it is asked to. If the `bundle`
command is unavailable, install Bundler first with `gem install bundler`.

**All supported optional plugin dependencies.** For plugin development, or for
running the specs of the plugins that need a gem:

```sh
bundle config set --local with plugins
bundle install
bundle exec rake
```

That adds `activerecord`, `sqlite3`, `nokogiri`, `sanitize` and `feedbag`,
and their specs then run as part of the ordinary suite. The setting
is written to the checkout's own `.bundle/config`, which is not committed;
`bundle config unset --local with` returns the checkout to the minimum, and
`bundle install` afterwards.

**One dependency at a time.** Start minimal and add only what a plugin you
actually use needs. Each optional gem is in a second, smaller group named after
what it is for, so the group name selects it on its own:

```sh
bundle config set --local with store     # activerecord and sqlite3
bundle install
```

Several at once are space-separated: `bundle config set --local with "store
html"`, and a Recipe using plugins from two groups needs exactly that. The group
names are in the table below, and "Working out what a Recipe needs, in a
checkout" takes one Recipe through choosing them.

In a checkout, `gem install <gem>` on its own is **not** enough: the checkout
resolves its gems through the bundle, so a gem the `Gemfile` does not mention is
not visible to it however plainly `gem list` shows it. Use the group, which is
why the groups exist. Outside a checkout — the installed gem, run as `automatic`
— there is no bundle and `gem install <gem>` is exactly right.

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
- A `LoadError` naming a gem means a plugin's optional dependency is not
  installed. `feed2console.yml` uses none, so at this point it means the
  installation itself; a message naming a gem and a plugin means the plugin,
  and "Optional plugin dependencies" below says what to install.

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

That Recipe needs three optional gems, because of the plugins it names rather
than because of the framework: `nokogiri` for `FilterImageSource`, and
`activerecord` and `sqlite3` for `StorePermalink`. See "Optional plugin
dependencies" below.

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

This table is the list. Which plugin needs which gem, how to install it, and
whether the plugin still works are all here, and nothing else repeats it.

None of these gems is installed by `gem install automatic` or by a default
`bundle install`. Install one only if you use the plugin.

**Installed gem**: `gem install <gem>`. **Checkout**: `bundle config set
--local with <group>` and `bundle install`, because `bundle exec` sees only the
bundle. `plugins` is every group in the first block at once.

| Plugin | Needs | Installed gem | Checkout group | Status |
| --- | --- | --- | --- | --- |
| `StorePermalink`, `StoreFullText`, `StoreDigest` | `activerecord`, `sqlite3` | `gem install activerecord sqlite3` | `store` | Supported |
| `FilterImageSource`, `FilterDescriptionLink`, `SubscriptionLink`, `SubscriptionTumblr`, `CustomFeedWeb` | `nokogiri` | `gem install nokogiri` | `html` | Supported (`SubscriptionTumblr` external) |
| `PublishMarkdown` | `nokogiri`, for HTML bodies only | `gem install nokogiri` | `html` | Supported; runs without it |
| `FilterSanitize` | `sanitize` | `gem install sanitize` | `sanitize` | Supported |
| `autodiscovery` and `inspect` subcommands | `feedbag` | `gem install feedbag` | `autodiscovery` | Supported |
| `FilterFullFeed` | `nokogiri`, and a siteinfo file | `gem install nokogiri` | `html` | Supported (external) |
| `CustomFeedSVNLog` | the `svn` command; no gem | — | — | Supported (external) |
| `ProvideFluentd`, `PublishFluentd` | `fluent-logger`, and a Fluentd instance | `gem install fluent-logger` | `fluentd` | Supported (external) |
| `PublishMemcached` | `dalli`, and a memcached server | `gem install dalli` | `memcached` | Supported (external) |
| `PublishAmazonS3`, `StoreFile` S3 path | `aws-sdk-s3`, and a bucket | `gem install aws-sdk-s3` | `s3` | Supported (external) |
| `PublishInstapaper` | an Instapaper account; no gem | — | — | Supported (external) |
| `PublishEject` | the `eject` or `drutil` command | — | — | Supported (external) |
| `NotifyIkachan` | an `ikachan` gateway you run | — | — | Supported (external) |
| `FilterOpenAI`, `FilterClaude`, `FilterGemini`, `FilterSakuraAI` | an account and an API token with that one service; no gem | — | — | Supported (external) |
| `PublishHatenaBookmark` | the current Hatena API, which it does not speak | — | — | Needs rework |

The `plugins` group is the first five rows: the optional gems of the plugins
whose specs need nothing but the gem. The gems below it are in their own groups
only, because each of those plugins also needs a service, a bucket or a
command, and installing a gem alone would not make the plugin — or its spec —
work.

Both S3 rows make their requirement lazily, so `StoreFile`'s ordinary HTTP
download path and `PublishAmazonS3` in `mode: test` work with no AWS gem
installed at all. Leaving `access_key` and `secret_key` out of the Recipe is the
better way to use them: the SDK then takes credentials from the environment, a
shared profile or an instance role, and no long-lived secret sits in a file.

Two gems left this table in v26.08 and are not needed by anything now:
`xml-simple`, which `CustomFeedSVNLog` used to parse `svn log --xml` and which
REXML — already a dependency of the framework — parses instead, and `nkf`,
which `FilterDescriptionLink` used to normalize a page's encoding and which the
HTML parser does for itself. If you installed either for this project, nothing
here wants it any more.

No optional group is installed by default and none is installed in required CI,
so these plugins are outside what a green build guarantees. Installing a group
brings the specs of its plugins into the ordinary `bundle exec rake` run, which
is how they are verified.

Using a plugin without its gem is not a mystery: the plugin says what is
missing, what needs it and how to get it, and the command exits `1`.

```text
automatic: The `activerecord` gem is not installed. It is needed by the store
plugins. Install it with `gem install activerecord`, ...
```

### Working out what a Recipe needs, in a checkout

The table says what a plugin needs. A Recipe needs the **sum** of what its
plugins need, worked out before the first run rather than discovered one failed
run at a time, and in a checkout that sum is a list of groups. The Quick Start's
Recipe — index pages watched for new articles, de-duplicated by content,
published as one Markdown document — is the worked example, shortened here to
one page:

```yaml
# ~/.automatic/config/web2markdown.yml
plugins:
  - module: CustomFeedWeb
    config:
      retry: 2
      interval: 2
      sites:
        - name: The Go Blog
          url: https://go.dev/blog/
          link_selector: 'a[href]'
          include:
            - '^https://go\.dev/blog/[^/]+$'
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

[`QUICKSTART.md`](QUICKSTART.md) runs that Recipe end to end, with the sites it
watches and what each plugin does. What follows is the part a checkout does
differently: turning those three plugins into a bundle that can run them.

**1. List the plugins the Recipe names.** They are the `module` lines, in order:
`CustomFeedWeb`, `StoreDigest`, `PublishMarkdown`.

**2. Look each one up in the table above.** What that lookup yields here, and
the whole of what this Recipe's dependencies are:

| Plugin | Needs | Checkout group |
| --- | --- | --- |
| `CustomFeedWeb` | `nokogiri`, to read the index pages | `html` |
| `StoreDigest` | `activerecord`, `sqlite3` | `store` |
| `PublishMarkdown` | nothing of its own | — |

`PublishMarkdown` is the row worth reading twice. It needs no gem: it reduces an
HTML body with `nokogiri` where one is installed and with its own substitution
where none is, so it neither adds a group here nor fails without one. A plugin's
row in the table is the answer, not a guess from what the plugin does.

**3. Add the groups up.** This Recipe needs `html` **and** `store`. Getting this
step half right fails half way through the run, because a plugin is loaded when
the pipeline reaches it and not before: with `html` alone, `CustomFeedWeb`
loads, fetches its pages and hands its feeds on, and the run then stops where
the second plugin is loaded.

```text
automatic: The `activerecord` gem is not installed. It is needed by the store
plugins. Install it with `gem install activerecord`, or in a source checkout add
its group to the bundle; see the optional plugin dependencies in
doc/DEPLOYMENT.md. (cannot load such file -- active_record)
```

The first plugin having worked is not the setup being finished. Read the whole
Recipe, then install once.

**4. Select the groups in the checkout.**

```sh
cd ~/automaticruby
bundle config set --local with "html store"
```

**5. Install them.**

```sh
bundle install
```

**6. Check what was selected.** This prints the setting Bundler will use, and
where it came from:

```sh
bundle config get with
```

```text
Set for your local app (/home/you/automaticruby/.bundle/config): [:html, :store]
```

**7. Run the Recipe.**

```sh
bundle exec bin/automatic -c ~/.automatic/config/web2markdown.yml
```

Run it twice. The second run publishes nothing, because `StoreDigest` has the
digest of everything the page listed, which is what makes the Recipe safe to put
in `cron` and is worth checking before scheduling any Recipe with an effect.

A store plugin's `db` is a **file name**, not a path: it is resolved under
`~/.automatic/db`, or under the checkout's own `db/` where that directory does
not exist yet, so a checkout run before `scaffold` keeps its database inside the
checkout. The `Using Database:` line of an `info`-level log names the file that
was opened, which is the way to check. `PublishMarkdown`'s `file` is the
opposite — a path, with `~` expanded — and the Recipe above uses each as it is
meant.

Adding a plugin to a Recipe later starts this over at step 1: a `FilterSanitize`
added to the Recipe above brings `sanitize` with it, and the `with` setting has
to name `sanitize` as well as `html` and `store`.

### Why `bundle exec`, and why `gem install` is not enough here

A checkout resolves its gems through Bundler whether or not you ask it to.
`lib/automatic/environment.rb` treats a `Gemfile` beside `lib/` as "this is a
source checkout" and requires `bundler/setup` before anything else loads, so
`bin/automatic` run from a checkout sees the bundle and nothing outside it. That
is what makes `gem install` the wrong tool there: the gem installs, `gem list`
prints it, plain `ruby -rnokogiri -e ''` loads it — and the checkout still
reports it as missing, because it is not in the bundle.

```sh
gem install nokogiri
gem list nokogiri                 # prints the gem that was just installed
./bin/automatic -c ~/.automatic/config/web2markdown.yml
# automatic: The `nokogiri` gem is not installed. It is needed by CustomFeedWeb...
```

Use the group, and then run through `bundle exec`, from the checkout directory:

```sh
cd ~/automaticruby
bundle exec bin/automatic -c ~/.automatic/config/web2markdown.yml
```

`bundle exec` matters for what it does when the bundle is **not** in the state
you think it is. The `require 'bundler/setup'` above is deliberately forgiving:
where Bundler is absent, or where a group has been selected but not yet
installed, it is rescued and the program falls back to whatever RubyGems can
activate — quietly, and against gems the `Gemfile.lock` never resolved.
Running the same command through `bundle exec` says so instead:

```text
bundler: failed to load command: bin/automatic (bin/automatic)
Could not find activerecord-8.1.3.1, sqlite3-2.9.6-x86_64-linux-gnu ... in
locally installed gems (Bundler::GemNotFound)
```

That is `bundle install` not having been run after step 4, stated as such.
`bundle exec` is also what keeps one habit for the whole checkout: the same
prefix runs the specs, the diagnostic subcommands and the Recipe, and typing
`automatic` instead would run the installed gem rather than the checkout.

**What "is not installed" means in that message.** It is the framework
reporting that **this process could not `require` the library**, which is wider
than "no copy of the gem exists on this machine". A gem installed by `gem
install` but outside the checkout's bundle produces it; so does a group selected
but not installed, and so does an installation under a different Ruby. The gem
name and the plugin name in the message are what to act on; whether to act with
a group or with `gem install` is decided by where you are running from, not by
the message.

To see what the bundle actually holds, ask the bundle rather than RubyGems:

```sh
bundle config get with           # which optional groups are selected
bundle show nokogiri             # where the bundle's copy is, or an error
bundle show activerecord
bundle show sqlite3
```

```sh
bundle exec ruby -rnokogiri      -e 'puts Nokogiri::VERSION'
bundle exec ruby -ractive_record -e 'puts ActiveRecord::VERSION::STRING'
bundle exec ruby -rsqlite3       -e 'puts SQLite3::VERSION'
```

Those three `require` the libraries the way the plugins do — note
`active_record` for the `activerecord` gem — under the same bundle the Recipe
will run under. `gem list` answers a different question and is the one to
distrust here: it lists what RubyGems has, which in a checkout is neither what
the plugins will load nor what a missing-gem message is about.

### All of the optional gems, or only the ones a Recipe names

Two ways to select groups, for two purposes:

```sh
bundle config set --local with plugins        # all of them, at once
bundle config set --local with "html store"   # what this Recipe needs
```

`plugins` is every gem in the first block of the `Gemfile` — `activerecord`,
`sqlite3`, `nokogiri`, `sanitize`, `feedbag` — and is meant for working **on**
the plugins: it brings their specs into the ordinary `bundle exec rake` run,
which is how those plugins are verified. It is the right setting for plugin
development and for a checkout you are developing in.

Naming the groups is the right setting for **running** Recipes, and is what the
design of the split asks for: a gem is installed by the operator who uses the
plugin that needs it, and a checkout that runs this Recipe has no reason to
build `sanitize` or to hold `feedbag`. Start there; `plugins` is not a shortcut
for having read the table, and a checkout that has installed everything hides
the group a Recipe of yours will need on the next machine.

Either way the setting is written to the checkout's own `.bundle/config`, which
is not committed and belongs to that checkout alone. That is what makes it hold:
`bundle install`, `bundle exec bin/automatic`, `bundle exec rake` and the
checkout's `bin/automatic` all read it, so the groups are selected once rather
than remembered at every command. Passing the environment variable instead —
`BUNDLE_WITH="html store" bundle install` — configures that one command and
leaves the next one without it, which produces exactly the confusing case above:
an installed group that the running process does not select.

To return the checkout to the minimum:

```sh
bundle config unset --local with
bundle install
```

The gems stay on the machine; what changes is that the bundle no longer includes
them, and the plugins that need them report them as missing again.

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

**`The <gem> gem is not installed. It is needed by ...`** — a plugin's optional
dependency could not be required. The message names the gem, the plugin and the
command to install it, and the table above says the same thing. In a checkout it
also means a gem installed outside the bundle, or a group selected but not
installed; "Why `bundle exec`, and why `gem install` is not enough here" above
tells the cases apart.

**`Automatic::NoPluginError: unknown plugin named ...`** — a Recipe names a
plugin that does not ship. Check the spelling against
[`PLUGINS.md`](PLUGINS.md) section 6; if the name is in section 8, the plugin
was removed because the service behind it no longer exists, and the Recipe
needs a different last step rather than a reinstall. Nothing has run when this
is raised.

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

Most of them need a credential or a service you run. Read
the Recipe before running it, and check the plugin's status in
[`PLUGINS.md`](PLUGINS.md) section 6.

## Uninstalling

```sh
gem uninstall automatic
rm -rf ~/.automatic          # or: automatic unscaffold, before uninstalling
```

Files that Recipes wrote outside `~/.automatic` — downloads under a `path` you
configured, for instance — are yours to remove.
