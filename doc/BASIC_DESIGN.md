# Basic design: a plugin pipeline for unattended processing

## 1. Purpose

This document says how Automatic Ruby is put together: what the pieces are, what
each is responsible for, which way they depend on each other, and how a value
travels through a run.

What the system is for belongs to [`REQUIREMENTS.md`](REQUIREMENTS.md). The
rules a change is held to belong to [`POLICY.md`](POLICY.md). The two public
contracts — the Recipe format and the plugin interface — are specified in
[`PLUGINS.md`](PLUGINS.md); this document explains the machinery that implements
them and does not restate them.

It stands on its own. Nothing in it is completed by a document kept in another
repository.

## 2. Design policy

- **The framework is the small part.** It loads a Recipe, finds classes by name,
  and calls them in order. It has no domain knowledge, and gaining some would be
  a design error rather than a feature.
- **Plugins are the large part, and they are replaceable.** They are found on a
  search path, not registered in a list, so that adding one touches no framework
  file and removing one leaves nothing dangling.
- **One value connects everything.** Because every plugin takes and returns the
  same shape, composition needs no adapter, no type negotiation and no schema.
- **The core is loadable without its plugins' dependencies.** `require
  'automatic'` pulls in the framework and nothing a plugin needs. Each plugin
  requires its own libraries, at the top of its own file, so that an absent gem
  is an error only for a Recipe that asked for that plugin.
- **The library never exits and never prints.** Exit status is decided by the
  entry point; user-facing text is written by the entry point or logged.

## 3. Composition

```text
bin/automatic                 process entry point; exit status only
        |
        v
lib/automatic/cli.rb          option parsing, subcommands, error reporting
        |
        +---------------------------+
        |                           |
        v                           v
lib/automatic.rb            lib/automatic/opml.rb      diagnostic helpers
  (run, directories)        lib/automatic/feed_parser.rb
        |
        +-------------------+
        |                   |
        v                   v
lib/automatic/recipe.rb  lib/automatic/pipeline.rb
        |                   |
        |                   v
        |            Automatic::Plugin::*      plugins/<category>/<name>.rb
        |                   |                  ~/.automatic/plugins/<category>/<name>.rb
        v                   v
lib/automatic/log.rb   lib/automatic/feed_maker.rb
        |
        v
   standard output
```

Dependency points downward, and there is no edge back up:

- `bin/automatic` knows only `Automatic::CLI`.
- `Automatic::CLI` knows the framework. Nothing in the framework knows the CLI.
- `Automatic::Pipeline` knows how to find and call a plugin. It knows no plugin.
- A plugin knows `Automatic::Log`, `Automatic::FeedMaker`,
  `Automatic::FeedParser` and its own libraries. It knows no other plugin, with
  one deliberate exception noted in section 4.9.
- `Automatic::Log` and `Automatic::FeedMaker` are leaves. They depend on nothing
  in this repository.

`Automatic::Recipe` and `Automatic::Pipeline` do not know each other. Both are
driven by `Automatic.run`.

## 4. What each part is for

### 4.1 `bin/automatic`

The process entry point, and deliberately almost empty. It puts the
installation's `lib` on the load path, requires `automatic/cli`, and exits with
the status `Automatic::CLI.run(ARGV)` returns.

It contains no option definition, no subcommand and no policy. Everything a test
would want to exercise is therefore in a library file, reachable without
spawning a process.

### 4.2 `lib/automatic/cli.rb` — `Automatic::CLI`

Everything that belongs to being a command:

- Builds the `OptionParser`: `-c/--config`, `-h/--help`, `-v/--version`.
- Holds the subcommand table (`scaffold`, `unscaffold`, `autodiscovery`,
  `feedparser`, `inspect`, `opmlparser`, `log`) as a hash of name to callable.
- Implements `scaffold` and `unscaffold`, which are the only filesystem
  operations the framework performs on its own behalf.
- Catches the framework's own exceptions, prints one line to standard error, and
  returns the exit status.

`CLI.run` **returns** an `Integer` and never calls `exit`. That is what lets a
spec assert on a status and on captured output instead of a subprocess.

Exit status is decided in exactly one place:

| Status | Meaning |
| --- | --- |
| `0` | The Recipe ran, or the subcommand did its work, or help or version was printed |
| `1` | The run or the subcommand failed, or no work was requested |
| `2` | The command line was rejected by the option parser |

The libraries a subcommand needs are required inside that subcommand, not at the
top of the file, so running a Recipe loads neither `feedbag` nor the OPML
parser. The framework's own requires still apply: `require 'automatic'` pulls in
the Recipe loader, the pipeline, the log and the two feed adapters, and through
them Ruby's `rss`.

### 4.3 `lib/automatic.rb` — `Automatic`

The module itself, holding the two directories the rest of the system resolves
paths against, and the one method that runs a job:

- `root_dir` — the installation root, set by the entry point.
- `user_dir` — `~/.automatic`, or an override when `AUTOMATIC_RUBY_ENV=test`,
  which is how the specs point the loader at a fixture directory without writing
  to a real home directory.
- `plugins_dir`, `config_dir`, `user_plugins_dir` — derived from those two.
- `run(recipe:, root_dir:, user_dir:)` — sets the directories and hands the
  Recipe to `Pipeline.run`.

It `require`s the framework's own files and nothing else. It does not require a
plugin, and a plugin's dependency never appears here.

### 4.4 `lib/automatic/environment.rb`

Bundler setup for a source checkout: if the repository's `Gemfile` is present,
set it up so `bin/automatic` resolves the locked gems.

It is a convenience for running from a checkout, not a requirement. When the gem
is installed normally there is no `Gemfile` to find and this file does nothing,
which is the correct behaviour: an installed library must not impose a bundle on
the program that requires it.

### 4.5 `lib/automatic/recipe.rb` — `Automatic::Recipe`

Turns a Recipe file into an object the pipeline can iterate.

- Resolves the path: a bare name is looked for in `~/.automatic/config` first,
  and anything not found there is treated as a path as given.
- Parses the YAML **safely** — the document may contain only the plain types a
  Recipe needs, so a Recipe cannot name a Ruby class to instantiate. Aliases are
  permitted, because they are a legitimate way to share a block of settings
  between plugins. This is a second line of defence, not the trust boundary; see
  [`REQUIREMENTS.md`](REQUIREMENTS.md) section 17.
- Wraps the result in `Hashie::Mash`, which is why a plugin entry answers to
  `plugin.module` and `plugin.config`, and why an absent setting reads as `nil`
  rather than raising.
- Applies `global.log.level` to `Automatic::Log`. This is the only `global` key
  the framework reads.
- Exposes `each_plugin`, which yields the entries of `plugins` in order.
- Raises `Automatic::InvalidRecipeError` for a document that is not a mapping,
  or that carries no usable `plugins` sequence.

It performs no validation of a plugin's own `config`. Whether a setting is
required, and what it must look like, is the plugin's business, because the
framework cannot know.

### 4.6 `lib/automatic/pipeline.rb` — `Automatic::Pipeline`

The core, and the shortest file that matters.

`load_plugin(module_name)` resolves a class name to a file:

1. `module_name.underscore` turns `SubscriptionFeed` into `subscription_feed`.
2. The category directories are listed, `~/.automatic/plugins/*` **before**
   `<root>/plugins/*`, so the user directory wins.
3. For each, if the directory's own name is a prefix of the underscored module
   name, the remainder is the file name: directory `subscription` and module
   `subscription_feed` give `subscription/feed.rb`.
4. The first existing file wins, and is registered with
   `Automatic::Plugin.autoload`, so the file is read when the constant is first
   used.
5. Nothing matched raises `Automatic::NoPluginError` naming the module.

The category directory is therefore not a label: it is half of the lookup key.
This is what lets a plugin be added by dropping in a file, and a shipped plugin
be overridden by putting a file of the same name in the user directory.

`run(recipe)` is the pipeline:

```ruby
pipeline = []
recipe.each_plugin do |plugin|
  mod = plugin.module
  load_plugin(mod)
  klass = Automatic::Plugin.const_get(mod)
  pipeline = klass.new(plugin.config, pipeline).run
end
```

Each plugin's return value is the next plugin's input. There is no branching, no
inspection of the value between steps, and no exception handling: a plugin that
raises ends the run, for the reason given in `REQUIREMENTS.md` section 12.

### 4.7 `lib/automatic/log.rb` — `Automatic::Log`

A `Logger` on standard output behind a level filter.

- `Log.level(name)` sets the threshold, from `global.log.level`.
- `Log.puts(level, message)` emits when `level` is at least the threshold.
- Levels are `info`, `warn`, `error`, `none`, compared by their position in that
  list; `none` is the threshold that admits nothing.
- Both a `String` and a `Symbol` are accepted for a level, because plugins have
  always passed both, and an unknown level is treated as `info` rather than
  raising in the middle of an unattended run.

It is a module with state rather than an injected object. That is a consequence
of plugins calling `Automatic::Log` directly, which keeps a plugin's signature
to `(config, pipeline)`.

### 4.8 `lib/automatic/feed_maker.rb` and `feed_parser.rb`

The adapters between "some data" and the pipeline shape.

- `FeedParser.get_url(url)` fetches a URL and parses it as a feed.
- `FeedParser.parse_html(html)` builds a feed whose items are the page's links,
  which is how the link and Tumblr subscription plugins work.
- `FeedMaker.generate_feed(hash)` builds one item-like object from plain values.
- `FeedMaker.create_pipeline(items)` builds one feed object from a list of them.
  Any plugin producing items from a non-feed source ends with this call.
- `FeedMaker.content_provide(url, data)` builds a one-item feed carrying an
  arbitrary payload in `content_encoded`, which is the route by which the XML
  subscription plugin feeds the Fluentd provide plugin.

Both use Ruby's bundled `rss` library. That is the reason the pipeline value has
the shape it has.

### 4.9 `plugins/` — `Automatic::Plugin::*`

Every plugin is a class in `Automatic::Plugin`, constructed with `(config,
pipeline)` and answering `run`. The contract is specified in
[`PLUGINS.md`](PLUGINS.md) section 3; what matters to this document is how the
categories divide responsibility:

| Category | Directory | Receives | Returns | Role |
| --- | --- | --- | --- | --- |
| `Subscription` | `subscription/` | usually an empty pipeline | a pipeline | Acquire from outside |
| `CustomFeed` | `custom_feed/` | usually an empty pipeline | a pipeline | Build a feed from a non-feed source |
| `Filter` | `filter/` | a pipeline | a pipeline | Select, reorder or rewrite |
| `Store` | `store/` | a pipeline | a pipeline, usually reduced | Persist, and drop what was seen before |
| `Provide` | `provide/` | a pipeline | the same pipeline | Emit the payload elsewhere |
| `Notify` | `notify/` | a pipeline | the same pipeline | Send a notification |
| `Publish` | `publish/` | a pipeline | the same pipeline | Send the result out, or print it |

The categories are a convention with one mechanical consequence — the directory
name is part of the lookup key (section 4.6) — and no other. Nothing enforces
that a `Filter` does not reach the network.

Two shared pieces sit inside `plugins/` rather than in `lib/`, because they are
plugin implementation and the framework does not use them:

- `plugins/store/database.rb` — the `Automatic::Plugin::Database` mixin: opens
  the SQLite database named in the Recipe, creates the table from the including
  class's `column_definition` when it is absent, and provides
  `for_each_new_feed`, which yields only items whose key is not already stored.
  `StorePermalink` and `StoreFullText` are this mixin plus a model and a column
  list.
- `plugins/subscription/chan_toru.rb` requires `g_guide.rb` and delegates to it.
  This is the one plugin-to-plugin dependency, it is explicit, and it is not a
  pattern to copy.

### 4.10 `db/`, `config/`, `assets/`

Fallbacks inside the installation, used when the corresponding part of the user
directory is absent: `db/` for SQLite files, `config/` for the example Recipes
that `scaffold` copies out, `assets/` for data files a plugin needs.

## 5. The flow of one run

```text
automatic -c feed2console.yml
  |
  | CLI parses the command line, resolves the recipe path
  v
Recipe.new(path)
  |  reads YAML safely, wraps in Hashie::Mash
  |  sets the log level from global.log.level
  v
Automatic.run(recipe:, root_dir:)
  |  sets root_dir and user_dir
  v
Pipeline.run(recipe)
  |
  |  pipeline = []
  |
  |  entry 1: module SubscriptionFeed
  |    load_plugin -> plugins/subscription/feed.rb
  |    SubscriptionFeed.new(config, []).run
  |      FeedParser.get_url(each configured feed)
  |    -> [feed]
  |
  |  entry 2: module FilterIgnore
  |    load_plugin -> plugins/filter/ignore.rb
  |    FilterIgnore.new(config, [feed]).run
  |      drops items matching a keyword
  |      FeedMaker.create_pipeline(kept items)
  |    -> [feed']
  |
  |  entry 3: module StorePermalink
  |    load_plugin -> plugins/store/permalink.rb
  |    StorePermalink.new(config, [feed']).run
  |      opens ~/.automatic/db/<db>, creates the table if absent
  |      for_each_new_feed: skips links already stored, inserts the rest
  |    -> [feed''] containing only what had not been seen
  |
  |  entry 4: module PublishConsole
  |    PublishConsole.new(config, [feed'']).run
  |      prints each item
  |    -> [feed'']
  v
the final value is discarded; CLI returns 0
```

Three properties of that flow are the design:

- The pipeline **narrows**. Subscription plugins produce, filters and stores
  reduce, publishers consume. A Recipe is normally read in that order.
- A store plugin is what makes a Recipe safe to run every five minutes. It is
  the only thing standing between the operator and a duplicate.
- Nothing between the steps inspects the value. The framework never looks inside
  a feed.

## 6. Settings

Two kinds, and they do not mix.

**Framework settings** come from the Recipe's `global` mapping, and there is one
that is read: `global.log.level`. `global.timezone` and `global.cache` appear in
the shipped examples and in Recipes in the wild, and nothing reads them. They
are kept — removing them would break nothing but would edit operators' files for
no gain — and they are documented as inert in
[`PLUGINS.md`](PLUGINS.md) section 2.4 so that no one adds a behaviour to them
by accident.

**Plugin settings** are the `config` mapping of a plugin entry, passed to the
constructor and read by nobody else. The framework does not validate, default,
merge or type-check them. A plugin that needs a value it was not given decides
what to do, and the common choice — treating an absent `retry` or `interval` as
zero — is why `nil.to_i` appears throughout the plugins.

There is no environment-variable configuration, with one exception:
`AUTOMATIC_RUBY_ENV=test` permits the user directory to be overridden, and
exists for the tests.

## 7. Error handling

The layers handle errors differently, and on purpose.

**Plugins** own transient failure. A plugin that reaches the network wraps the
attempt, logs the failure, and retries `retry` times with `interval` seconds
between attempts. What a plugin must not do is swallow an error and return a
value that looks like success.

**The framework** owns nothing it cannot fix, so it catches nothing. Its own
failures are named:

| Exception | Raised when |
| --- | --- |
| `Automatic::NoRecipeError` | `Pipeline.run` was given no Recipe |
| `Automatic::NoPluginError` | No file was found for a module named in a Recipe |
| `Automatic::InvalidRecipeError` | The Recipe is not a mapping, or has no plugins |

All three derive from `Automatic::Error`, so a caller can rescue the framework's
failures without rescuing everything.

**The CLI** is the only place that turns an exception into a message and a
status. It reports the framework's errors as one line on standard error and
returns `1`. Anything else it lets propagate, because an unexpected exception is
a defect and its backtrace is wanted.

## 8. Logging and output

- A library file never calls `puts`. It logs.
- `Automatic::CLI` writes to standard error for diagnostics and standard output
  for requested output — help, version, and the results of the diagnostic
  subcommands.
- Publishing plugins whose entire purpose is to print (`PublishConsole`,
  `PublishConsoleLink`) write to an output object held in an instance variable,
  defaulting to `$stdout`. That is what lets their specs assert on what was
  printed by substituting a double.

## 9. Testability

The design choices that exist for the tests:

- `CLI.run` returns a status instead of exiting, so command-line behaviour is a
  unit test.
- `Automatic.user_dir=` accepts an override under `AUTOMATIC_RUBY_ENV=test`, so
  the plugin loader can be pointed at `spec/user_dir` and the user-directory
  precedence rule can be asserted. `spec/user_dir/plugins/store/mock.rb` exists
  for exactly that.
- The plugin contract is a constructor and one method with no ambient input, so
  a plugin spec is: build a pipeline, construct, `run`, assert on the result.
  `AutomaticSpec.generate_pipeline` builds the pipeline.
- Each plugin requires its own libraries in its own file, so a plugin whose gem
  is not installed is one spec that does not load, rather than a suite that does
  not start.

The default suite covers the framework and the plugins that need neither the
network nor a credential. What that leaves out, and why, is in
[`PLUGINS.md`](PLUGINS.md) section 6 and in the README's testing section.
