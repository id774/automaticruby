# Requirements: a plugin pipeline for unattended processing

## 1. Purpose of this document

This document states what Automatic Ruby is for, what it accepts, what it
produces, and where its responsibility ends. It does not describe how any of it
is built; that belongs to [`BASIC_DESIGN.md`](BASIC_DESIGN.md), and how a change
to it is carried out belongs to [`POLICY.md`](POLICY.md). The two public
interfaces it names — the Recipe and the plugin contract — are specified in
[`PLUGINS.md`](PLUGINS.md).

It stands on its own. Nothing in it is completed by a document kept in another
repository.

Where this document says the software *does* something, that is a statement
about the present implementation, reconstructed by reading it. Where it says the
software *shall* do something, that is a requirement a change is held to.

## 2. Name

`automaticruby`, published as the RubyGem `automatic` and invoked as the command
`automatic`. The repository name carries the language because the framework is
the product: a Ruby program whose behaviour is written in Ruby plugins and
assembled in a configuration file.

## 3. Purpose

A person has a recurring job that consists of acquiring information, processing
what is useful, optionally persisting a record so it is not handled twice, and
publishing a portable result. Tomorrow they have another job
of the same shape with different endpoints. Writing each as a script means
writing the fetching, the filtering, the de-duplication and the retrying again
every time.

Automatic Ruby exists so that those jobs are *assembled* rather than written. A
step is a plugin — a small Ruby class with one method. A job is a Recipe — a
YAML file naming the plugins in order and their settings. Running the job is one
command, which is safe to put in `cron`.

The framework's contribution is exactly three things:

- a uniform contract every step obeys, so that steps compose,
- a value passed from step to step, so that they have something to compose over,
- a loader that finds a step by name, so that a Recipe can name it.

Everything else — what is fetched, what is filtered, what is published — belongs
to a plugin, and plugins are expected to come and go.

## 4. What it is not

- **Not an application.** It has no behaviour of its own. With no Recipe it does
  nothing, and every useful thing it does is a plugin's doing.
- **Not a daemon or a scheduler.** One invocation runs one Recipe once and
  exits. Repetition is `cron`'s job, and periodic running is deliberately left
  outside; see section 15.
- **Not a web application.** It serves nothing and listens on nothing.
- **Not a feed reader.** Feeds are the shape the pipeline value happens to take
  (section 8), not the purpose. A Recipe that never touches a feed is a normal
  use of it.
- **Not a general workflow engine.** There are no branches, no loops, no
  conditions and no fan-out. A Recipe is a straight line, and it stays one.
- **Not a hosted or multi-tenant system.** It runs as one person, on one
  machine, against that person's own accounts and files.
- **Not a sandbox.** A Recipe names Ruby classes and those classes run with the
  full privileges of the invoking user. See section 17.

## 5. Who uses it

One person, on their own machine or their own server, running their own Recipes
against their own accounts. They are able to read and write Ruby, because
writing a plugin is the intended way to extend the system, and the plugin
contract is small enough that this is a reasonable expectation rather than a
burden.

There is no notion of a second user, no account, no permission and no
separation. Two people sharing a Recipe share the credentials in it.

## 6. Where it runs

- A Unix-like system: GNU/Linux and macOS are what it is used on.
- A maintained Ruby (section 20), installed either from RubyGems or from a
  source checkout.
- Unattended, from `cron`, as often as the operator chooses.

Windows is not supported. Nothing is known to be deliberately incompatible with
it, but no plugin, no path handling and no test is written with it in mind, and
several plugins shell out to Unix commands.

## 7. The two public interfaces

Two things in this repository are interfaces that people outside it depend on,
and they are treated accordingly.

### 7.1 The Recipe

A Recipe is a YAML file listing the plugins of one job, in order, each with its
settings. Its structure is specified in [`PLUGINS.md`](PLUGINS.md) section 2.

A Recipe written for an earlier release shall keep working. Recipes live outside
this repository, in `~/.automatic/config` and in operators' `cron` entries, and
this repository cannot see them, cannot migrate them and shall not silently
change what they mean. Removing a key, renaming a key, changing a default so
that an unchanged Recipe does something else, and changing how a value is
interpreted are all breaking changes, are made only deliberately, and are
recorded in [`VERSIONS`](VERSIONS).

Adding an optional key with a default that preserves current behaviour is not a
breaking change.

### 7.2 The plugin contract

The contract a plugin class obeys — where it lives, how it is named, how it is
constructed, what it receives and what it must return — is specified in
[`PLUGINS.md`](PLUGINS.md) section 3.

It is an interface because plugins exist outside this repository, under
`~/.automatic/plugins`, and the framework loads them by the same rules it loads
its own. Changing the contract breaks code this repository has never seen.

## 8. The pipeline value

Every plugin receives one value and returns one value. That value is the
pipeline, and it is:

> an `Array` of feed objects, where a feed object responds to `#items`, and each
> item responds to `#title`, `#link`, `#description`, `#date`, `#author`,
> `#comments`, `#source`, `#enclosure` and `#content_encoded`.

In practice the elements are RSS objects produced by Ruby's `RSS::Maker` or by
`RSS::Parser`. `Automatic::FeedMaker` builds them from plain values, so a plugin
that acquires something which is not a feed — a row of a TSV file, an API
response, a weather report — converts it into this shape and the rest of the
pipeline is unaffected.

This is the framework's one substantive constraint on plugins, and it is what
makes them compose. Three consequences are requirements:

- A plugin shall accept this shape and return this shape. A plugin that returns
  something else ends the pipeline for every plugin after it.
- `link` may be `nil`. Several filters signal "not applicable" by setting it,
  and a plugin that dereferences it without checking is at fault.
- The names above are RSS names, and they are used for values that are not RSS.
  `title` may hold a weather condition and `description` may hold an arbitrary
  string. This is a known cost of having one shape, and it is accepted.

The value has no schema beyond that, no validation and no version. A plugin that
needs a field the previous plugin never set gets `nil`.

This is an **internal** representation, and it is not a statement about what a
run produces. A plugin that writes the pipeline out in some other form — a
Markdown document, a row in a database, a request body — serializes it at the
moment it leaves the pipeline, and the value the next plugin receives is
unchanged. An output format is therefore never a second pipeline
representation, and shall not become one; see section 10.2.

## 9. Input

The framework itself reads:

- **the Recipe**, named by `-c` (section 11),
- **the user directory**, `~/.automatic` (section 13),
- **plugin files**, from the user directory and from the installed package.

Everything else is read by a plugin, on its own account. Feeds, web pages, APIs,
TSV files, XML documents, a Subversion repository and a SQLite database are all
plugin inputs, not framework inputs.

The framework passes no ambient input to plugins. A plugin's entire input is the
`config` it is given and the pipeline it receives.

## 10. Output

### 10.1 What the framework writes

The framework itself writes:

- **a log**, to standard output (section 14),
- **the user directory**, when `scaffold` is asked for.

Everything a run actually accomplishes is written by a plugin: a file, a row in
SQLite, a request to a remote service, a line on the terminal. The framework
does not know what any of it is and does not verify it.

The final pipeline value is discarded. A Recipe whose last plugin only
transforms the pipeline has done nothing observable, and that is not an error.

### 10.2 What a run publishes

Where the collected information ends up is decided by the Recipe, and the
plugins that decide it are the `Publish` category. Two kinds of destination have
always existed side by side: a remote service, reached with a credential over
the network, and something local — the terminal, a file, a database. Neither is
the system's purpose. Automatic Ruby is not a means of feeding one particular
reader, one particular service or one particular protocol, and a requirement
written as though it were would be wrong about what the system is for.

Leaving the collected information behind as a **document that outlives the run**
is as much a use of the system as sending it somewhere. That document is read by
a person, kept in version control, searched with ordinary Unix tools, and given
to a program — including a large language model or an agent — as input to
summarize, classify or reorganize. These are the same document and the same
requirement, not two.

**Markdown is the standard publication format** for that purpose, in the sense
that it is what a Recipe publishes when it has no reason to publish to a
particular service. Its properties are the reason, and they are technical ones:

- a person reads it as it is, with no tool and no rendering step;
- it diffs and merges, so a growing document belongs in Git;
- `grep`, `sed` and the rest operate on it without a parser;
- a program consumes it as text, which is the form a language model or an agent
  takes its input in;
- it needs no service, no account, no credential and no network;
- it is plain text, so it stays readable for as long as the filesystem does.

The requirements that follow:

- **A publication format shall be available that needs nothing outside the
  machine.** A Recipe that collects, filters and de-duplicates shall be able to
  finish by writing what it has, without an account anywhere.
- **Markdown output is an ordinary Publish plugin**, subject to the plugin
  contract of section 7.2 and to nothing else. It is not a framework feature,
  the framework gains no knowledge of Markdown, and section 23 applies to it as
  to anything else.
- **Nothing is published implicitly.** A Recipe publishes what it names and
  nothing more. The framework shall not append a publishing step to a Recipe
  that does not ask for one, and a Recipe written before Markdown output existed
  shall behave exactly as it did.
- **The output format is not the pipeline value.** Serializing to Markdown
  happens at the boundary, in the publishing plugin, and leaves section 8's
  value untouched. No second representation is introduced, and the plugins
  before and after are unaffected.
- **RSS and Atom remain input formats.** `SubscriptionFeed` and the rest are
  unaffected by any of this: a feed is still one of the ordinary ways to acquire
  something, and none of it is deprecated. That the pipeline value has the shape
  of a feed is an internal matter (section 8); it neither obliges a run to
  publish a feed nor makes feeds less useful to read.

## 11. The command line

One executable, `automatic`, with two modes.

**Running a Recipe.** `automatic -c RECIPE` loads the Recipe and runs its
pipeline. `RECIPE` is either a path, or a bare name resolved inside
`~/.automatic/config`.

**Subcommands.** Auxiliary tools that do not involve a Recipe:

| Subcommand | What it is for |
| --- | --- |
| `scaffold` | Create the user directory (section 13) |
| `unscaffold` | Remove the user directory |
| `autodiscovery <url>` | Print the feed URLs advertised by a page |
| `feedparser <url>` | Parse a feed and print the result |
| `inspect <url>` | Discover a page's feeds, then parse the first |
| `opmlparser <path>` | Print the feed URLs in an OPML file |
| `log <level> <message>` | Emit one line in the framework's log format |

The last five exist to answer "will this work as a Recipe input?" before writing
the Recipe. They are diagnostic and they may print freely.

Requirements on the command line:

- `--help` and `--version` shall be available, shall print to standard output
  and shall exit `0`.
- Exit status shall distinguish success from failure: `0` when the requested
  work was done, `1` when it was not, `2` when the command line itself was
  rejected. A run that fails shall not exit `0`.
- Diagnostics shall go to standard error, so that the output of `feedparser` and
  friends can be redirected without collecting them.
- The set of subcommands and the meaning of `-c` are part of the compatibility
  promise of section 7.1.

## 12. Execution and failure

A run is: load the Recipe, then for each plugin entry in order, load the class,
construct it with its `config` and the current pipeline, call `run`, and take
the result as the pipeline for the next entry.

The requirements on failure:

- **A pipeline is not partially rerunnable.** There is no checkpoint and no
  resume. A failed run is rerun from the start, so plugins that must not repeat
  their effect are responsible for saying so; `StorePermalink` exists for this.
- **A plugin that raises ends the run.** The framework does not catch exceptions
  from plugins. The Recipe is a sequence in which each step consumes the
  previous one's output, so continuing past a failed step would run the
  remaining steps on a value their author never intended.
- **Retrying belongs to the plugin.** Plugins that reach the network take
  `retry` and `interval` and handle their own transient failures. The framework
  offers no retry, and shall not acquire one that changes what a Recipe means.
- **A failure shall be visible.** Whatever a plugin decides to do about an
  error, it logs it, and the process exit status reflects whether the run
  completed. Silently returning an empty pipeline is a defect.
- **A Recipe naming a plugin that does not exist fails immediately**, before any
  plugin runs, with a message naming the plugin.

## 13. The user directory

`~/.automatic` is where an installation's own material lives, so that it
survives upgrading or reinstalling the gem.

| Path | Holds |
| --- | --- |
| `~/.automatic/config` | Recipes. A bare `-c` name is resolved here. |
| `~/.automatic/plugins` | The operator's own plugins, in category subdirectories. |
| `~/.automatic/db` | SQLite databases written by the store plugins. |
| `~/.automatic/assets` | Data files plugins need, such as the fulltext siteinfo. |

Requirements:

- The user directory takes precedence over the installed package. A plugin under
  `~/.automatic/plugins` shadows a plugin of the same name shipped in the gem.
  Overriding a shipped plugin without editing the installation is the point.
- Each part is optional. Where a directory is absent the framework falls back to
  the corresponding directory inside the installation, and a Recipe that needs
  none of them runs without a user directory at all.
- `scaffold` creates the directory and seeds it: the category subdirectories, the
  example Recipes, and the shipped assets. It shall not overwrite what is
  already there.
- `unscaffold` removes the whole directory, including Recipes and databases the
  operator put there. It is destructive by design and says so.

## 14. Logging

One log, to standard output, one line per event, through Ruby's `Logger`.

- Four levels, in order: `info`, `warn`, `error`, `none`. `none` silences
  everything.
- The level is set per Recipe, by `global.log.level`. It is the one framework
  setting a Recipe carries.
- The framework logs which Recipe was loaded and which database was opened.
  Plugins log what they fetched, what they skipped and what failed.
- The log is what the operator has after an unattended run. Where a plugin
  decides not to fail, the log is the only record that anything went wrong, so
  a swallowed error is logged at `warn` or `error`, never at `info` and never
  not at all.

## 15. Scheduling

Out of scope, deliberately. The system provides no scheduler, no daemon, no lock
file and no "run every N minutes". `automatic -c recipe.yml` in a `cron` entry
is the intended deployment, and `cron` keeps the responsibility for when.

Two consequences the operator owns: overlapping runs are possible if a run
outlasts its interval, and a Recipe that reaches a rate-limited service is
scheduled with that in mind.

## 16. External services

The framework reaches nothing. Plugins reach the network, and where they do:

- The endpoint, the protocol, the authentication and the failure handling belong
  entirely to that plugin.
- Credentials are given to the plugin in its Recipe `config` (section 17).
- TLS certificates shall be verified. A plugin shall not disable verification.
- Nothing is fetched on the framework's own initiative: no update check, no
  telemetry, no phone-home.

Services shut down and APIs are replaced, and whether a given plugin still works
is a fact about the outside world rather than about this repository. It is
recorded per plugin in [`PLUGINS.md`](PLUGINS.md) section 6 and kept current
there. Three requirements follow:

- **A shipped plugin shall be practically usable on the supported Ruby
  versions.** Shipping it is a statement that it does what its entry says,
  given what that entry says the operator must provide. A plugin for which that
  statement can no longer be made shall be corrected or removed; it shall not
  be carried indefinitely as a record of what once existed, which is what the
  version control history is for.
- **A plugin that cannot work shall say so** — in the catalogue and, where it
  runs at all, in its log output. It shall not be quietly left to fail at
  runtime.
- **A plugin shall never be made to pass a test by simulating a service that no
  longer exists.** Deleting the test, or marking it as requiring a service that
  is gone, is correct; a stub that makes a dead integration look alive is not.

## 17. Trust and credentials

**A Recipe is trusted local configuration**, equivalent to a shell script the
operator wrote. This is the trust boundary, and everything below follows from
it.

A Recipe names Ruby classes and the framework loads and runs them. A Recipe also
names plugin *files*, indirectly, through the loader's search path. Anyone who
can write a Recipe, or write a file under `~/.automatic/plugins`, can execute
arbitrary code as the operator. Therefore:

- Recipes and plugin directories are the operator's own, protected by file
  permissions. There is no supported use in which they come from elsewhere.
- A Recipe from an untrusted source is not to be run, and the system offers no
  mode in which doing so would be safe. This is not a limitation to be lifted by
  hardening the YAML parser.
- Even so, the Recipe parser shall not be a second, avoidable path to code
  execution: YAML shall be loaded so that the document cannot name arbitrary
  Ruby classes to instantiate. Refusing that costs nothing, since no Recipe
  needs it.

Credentials — API tokens, passwords, keys — are values in the Recipe's `config`,
which means a Recipe holding them is a secret file, and the operator restricts
its permissions. This is a weakness inherited from the original design, and it
is recorded rather than glossed:

- No credential shall be committed to this repository, in a Recipe, an example,
  a fixture or a test.
- No credential shall be written to the log. A plugin that logs its own settings
  is a defect.
- The example Recipes shipped in `config/` shall need no credential.

## 18. Persistence

Two kinds, both a plugin's business rather than the framework's.

**SQLite, through ActiveRecord.** The store plugins keep a table of what has
been seen so that the next run skips it: `StorePermalink` on the link,
`StoreFullText` on the link and title with the article body. The database file
is named in the Recipe and lives in `~/.automatic/db`, or in the installation's
`db/` when there is no user directory. The table is created on first use from
the plugin's own column definition; there are no migrations and no schema
version.

Requirements: ActiveRecord is used as a library and this is not a Rails
application; nothing shall introduce one. Equally, ActiveRecord shall not be
replaced by a hand-written database layer merely because it is a large
dependency — it is what the existing databases were written by, and operators
have those files. It is the store plugins' dependency and not the framework's:
`activerecord` and `sqlite3` shall be installed by the operator who uses those
plugins, and a Recipe that stores nothing shall run without either.

**The filesystem.** `StoreFile` downloads what the pipeline points at and
rewrites the item's link to a `file://` URI, which is how a later publishing
plugin knows to upload a local file rather than a remote one.

## 19. Packaging and distribution

- Distributed as the RubyGem `automatic`, installable with `gem install
  automatic`, providing the `automatic` executable.
- Also usable from a source checkout, through `bundle exec bin/automatic`.
- Dependencies are declared, versioned and resolved by Bundler and RubyGems.
  Nothing is vendored into this repository.
- **The core install shall be small.** A dependency needed by one plugin shall
  not be required to install the framework or to run a Recipe that does not use
  that plugin; see [`POLICY.md`](POLICY.md) section 9. Requiring an operator who
  publishes to a console to install an AWS SDK is a defect.
- Gem sources shall be HTTPS and shall be currently operating.

## 20. Supported Ruby

Two statements are made here, and they are deliberately different.

**The supported range** is **Ruby 3.3 through Ruby 4.0**.

- The floor is **Ruby 3.3**: the oldest maintained release the dependency set is
  resolved and tested against. Nothing older is tested or supported.
- The code shall be written against APIs the whole range shares. Where a Ruby
  release deprecates or removes one, the replacement that works on the whole
  range is used, rather than a `RUBY_VERSION` branch; see
  [`POLICY.md`](POLICY.md) section 2.4.
- The gemspec's `required_ruby_version` is a lower bound and not an upper one,
  so a Ruby newer than the range is permitted rather than refused. Refusing one
  would need a new release of this gem to lift.
- The floor shall not be lowered to accommodate an unmaintained Ruby, and shall
  not be raised to the newest release for its own sake. It moves when a
  dependency the project needs moves it, or when the version drops out of the
  distributions the project is used on.

**The continuously validated versions** are **3.3, 3.4 and 4.0** — the ends of
the range and the release in the middle.

- CI runs representative versions rather than every intermediate release. The
  cost of a matrix entry is paid on every commit, and a third entry between two
  that pass says little about a range whose code shares one set of APIs.
- **A version's absence from the matrix is not a statement that it fails.** It
  is a statement that it is not verified on every commit. Nothing is written to
  be deliberately incompatible with a supported Ruby that the matrix omits.
- Adding a released Ruby to the matrix is how support for it becomes continuous,
  and is a small change.

One statement of the supported range lives in the gemspec, one statement of the
validated set lives in the CI matrix, and the README and the documents agree
with both.

## 21. Portability

- No compiled extension of this repository's own. Extensions come only from
  dependencies.
- No absolute path outside `~/.automatic` and the installation directory.
- Nothing tied to a particular distribution, filesystem layout or init system.
- Shelling out is a plugin's business, and a plugin that does it is expected to
  fail cleanly where the command is absent.

## 22. Testability

- The framework's own units — the Recipe loader, the plugin loader, the
  pipeline, the log — shall be testable without a network, without credentials
  and without a user directory.
- **The default test suite shall reach no network and require no credential.**
  A test that needs either is not part of it.
- A plugin's test constructs the plugin with a `config` and a pipeline, calls
  `run`, and asserts on the returned pipeline. The framework provides the means
  to build a pipeline for this.
- Where a plugin's dependency cannot be installed or its service no longer
  exists, its test is excluded from the default suite by that fact and not by a
  simulation of the service. See section 16.
- The integration Recipes under `test/integration` are run by hand against real
  services, and are not part of the default suite or of CI.

## 23. Simplicity

The framework is under seven hundred lines of Ruby and is meant to stay that
size. It is the small fixed part that plugins are written against, and it earns
its keep by not changing.

- A capability that can live in a plugin lives in a plugin.
- A framework feature that only one plugin would use does not belong to the
  framework.
- Long-standing behaviour is left alone unless there is a reason beyond taste. A
  pipeline that has been in `cron` for a decade has earned the benefit of the
  doubt.

## 24. Licence

Automatic Ruby is dual-licensed under the GNU General Public License, version 3,
or the GNU Lesser General Public License, version 3. A user may choose either
license at their discretion. See [`LICENSE.md`](LICENSE.md),
[`COPYING`](COPYING) and [`COPYING.LESSER`](COPYING.LESSER).
