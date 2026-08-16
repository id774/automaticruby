# Implementation Policies

This document decides how this repository is implemented: the coding rules, the
responsibilities of the parts and the direction of dependency between them, the
handling of settings and credentials, the approach to tests and documentation,
the versioning scheme, and the criteria a change is judged by.

It stands on its own. No rule here is completed by a document kept in another
repository, and a subject it does not cover is a gap in this document, to be
filled here rather than looked up elsewhere.

What the system is for belongs to [`REQUIREMENTS.md`](REQUIREMENTS.md); how it
is composed belongs to [`BASIC_DESIGN.md`](BASIC_DESIGN.md); the Recipe format
and the plugin contract belong to [`PLUGINS.md`](PLUGINS.md). This document does
not restate them; it decides how they are carried out.

The Invariants below decide over the rest of it.

---

## 1. General Policy

### 1.1 Purpose and scope

- **Automatic Ruby is a framework, and the framework is the small part.** It
  loads a Recipe, finds classes by name and calls them in order. Nearly every
  change belongs in a plugin, and a change that adds domain knowledge to the
  framework needs a reason beyond convenience.
- **It is one person's tooling, run unattended from `cron`.** It is not a
  service, not multi-tenant and not a product. That premise decides several
  rules below that would otherwise look lax — the Recipe being trusted, chiefly.
- This document applies to everything committed here: the library, the plugins,
  the executable, the tests, the packaging and the documents.
- Ruby is the implementation language and stays the implementation language. A
  proposal to reimplement the core in another language is out of scope, and so
  is turning this into a Rails application.

### 1.2 Invariants

These come before every other rule here. Some of what they forbid is what a
general policy would otherwise ask for.

1. **The Recipe format and the plugin contract are interfaces, and this
   repository is not free to change them.** Both are depended on by files this
   repository cannot see: Recipes in `~/.automatic/config`, plugins in
   `~/.automatic/plugins`. A change that breaks either is deliberate, is
   justified, and is recorded in [`VERSIONS`](VERSIONS).
2. **The pipeline value has one shape.** Every plugin takes and returns an array
   of feed objects. Introducing a second representation would end composability,
   which is the whole of what the framework provides.
3. **The plugin architecture is not replaced.** Recipes are not superseded by
   hard-coded procedures, the loader is not replaced by a registry that must be
   edited to add a plugin, and the framework does not become a single
   application with the plugins folded into it.
4. **A dependency needed by one plugin is not a dependency of the framework.**
   Installing the gem must not pull in an SDK for a service the operator does
   not use. See section 9.
5. **A failure is never silent.** No `rescue` that returns an empty pipeline as
   if nothing happened, and no run that exits zero after something went wrong.
6. **The default test suite reaches no network and needs no credential.** None
   is configured in CI.
7. **A plugin that cannot work is never simulated into working.** Stubbing a
   dead service to make a test pass, or to make the catalogue look better, is
   forbidden outright. Removing the plugin is the correct outcome. See
   section 4.
8. **No credential is committed**, in a Recipe, an example, a fixture or a test,
   and none is written to the log.
9. **Historical release history is not rewritten.** Past versions and their
   dates in [`VERSIONS`](VERSIONS) are a record, not a thing to tidy.
10. **The licence is GPL version 3 or LGPL version 3.** Automatic Ruby is
    dual-licensed, and a user may choose either license at their discretion. New
    files use the same dual license.

### 1.3 Design philosophy

- Simple comes before clever. Common work should fit in a short Recipe, and a
  new abstraction needs a concrete problem the existing plugin contract cannot
  solve.
- Documentation examples must run, and the Quick Start uses Supported plugins
  only. Supported paths receive maintenance priority over integrations that
  need rework.

- Prefer the smallest change that solves the problem. A pipeline that has run in
  someone's `cron` for a decade has earned the benefit of the doubt.
- Understand why something exists before replacing it. A constant that looks
  arbitrary usually encodes an operational fact.
- A capability that can live in a plugin lives in a plugin.
- Where a decision looks odd, a comment gives the reason, so that a later change
  does not quietly undo it.
- Old is not a defect. Neither is unfashionable. A defect is something that does
  not work, is not understood, or cannot be tested.

### 1.4 The parts and the direction of dependency

```text
bin/automatic
      |
      v
lib/automatic/cli.rb
      |
      v
lib/automatic.rb  ->  recipe.rb  ->  pipeline.rb
      |                                  |
      |                                  v
      |                        Automatic::Plugin::*
      v                                  |
log.rb  feed_maker.rb  feed_parser.rb  http.rb
      ^----------------------------------+
```

Dependency points one way and there is no edge back up:

- **`bin/automatic` knows only the CLI.** It puts `lib` on the load path,
  requires `automatic/cli`, and exits with the status it is given. No option, no
  subcommand and no policy lives there.
- **The CLI knows the framework; the framework does not know the CLI.** Nothing
  under `lib/automatic/` other than `cli.rb` may reference it.
- **`Pipeline` knows how to find and call a plugin; it knows no plugin.** A
  reference to a plugin class name in the framework is a design error.
- **A plugin knows `Log`, `FeedMaker`, `FeedParser`, `Http` and its own
  libraries.** It does not know another plugin, does not know the CLI, and does
  not reach into `Automatic` for directories other than through the helpers
  provided.
- **`Log`, `FeedMaker`, `FeedParser` and `Http` are leaves.** They depend on
  nothing else in this repository.
- A new responsibility goes to the part that owns it. Where it appears to belong
  to two, the boundary is wrong and is corrected, rather than the code being
  written across it.

### 1.5 The plugin boundary

- The framework's knowledge of a plugin is: its name, its file's location, its
  constructor's two arguments and its `run` method. It does not know a plugin's
  category semantics, its settings, its dependencies or its failure modes.
- The framework does not validate a plugin's `config`. It cannot know what is
  valid, and pretending otherwise would put plugin knowledge in the framework.
- The framework does not inspect the pipeline between plugins.
- A plugin does not modify framework state. It does not set `Automatic.root_dir`
  or `Automatic.user_dir`, and it does not change the log level.
- Plugin-to-plugin dependency is avoided. A plugin that wants another plugin's
  result is a Recipe with two entries in it.
- Shared plugin code that the framework does not use stays under `plugins/`, not
  in `lib/`. `plugins/store/database.rb` is where it is for that reason.

### 1.6 Configuration

- A Recipe is the whole of a job's configuration. There is no second file, no
  configuration directory, and no environment-variable settings.
- The one exception is `AUTOMATIC_RUBY_ENV=test`, which permits the user
  directory to be overridden. It exists for the tests and is not an operator
  interface.
- The framework reads exactly one `global` key, `global.log.level`. Adding a
  second is a change to the Recipe format and is judged as one.
- `global.timezone` and `global.cache` are inert and stay inert. They are not
  removed — that would edit operators' files for no gain — and they are not
  given a meaning.
- A plugin reads its settings from `@config` by string key, tolerates `nil` for
  the mapping and for any key, and follows the established names: `retry`,
  `interval`, `db`, `path`.
- Not every constant becomes a setting. A value the operator would plausibly
  change is a setting; a value that is part of what the plugin means stays in
  the code.

### 1.7 Error handling

- **The framework catches nothing from a plugin.** A plugin that raises ends the
  run, for the reason given in `REQUIREMENTS.md` section 12. Adding a blanket
  rescue around plugin execution would change what every existing Recipe means
  and is not done.
- **A plugin owns its transient failures**, through `retry` and `interval`, and
  logs each failed attempt.
- The framework's own failures have named classes in `lib/automatic.rb`:
  `Automatic::Error` and, under it, `NoRecipeError`, `NoPluginError` and
  `InvalidRecipeError`. A new framework failure gets a class rather than a
  `RuntimeError` with a message.
- **`rescue` without a class is `rescue StandardError` and that is what is
  meant.** A bare `rescue` is acceptable in a plugin's retry block, where the
  point is that any failure of the attempt is retried, and unacceptable
  elsewhere. Where used, it logs.
- An unexpected exception is left to propagate out of the CLI. It is a defect
  and its backtrace is wanted.
- **The library never calls `exit` or `abort`.** Exit status is decided at the
  process entry point, from the value `Automatic::CLI.run` returns.

### 1.8 Logging and output

- **A library file never calls `puts`, `print` or `warn`.** It logs, through
  `Automatic::Log`.
- The CLI writes diagnostics to standard error and requested output — help,
  version, subcommand results — to standard output.
- A plugin whose purpose is to write to the terminal holds its output object in
  an instance variable defaulting to `$stdout`, so that a test can substitute it.
- `info` says what a step did, `warn` says what was skipped, `error` says what
  failed. An error that was rescued is logged at `warn` or `error`, never at
  `info`.
- No log line contains a credential. A plugin that logs its own settings
  wholesale is a defect.

### 1.9 Filesystem access

- The framework touches two roots: the installation directory and
  `~/.automatic`. Nothing else, and no absolute path elsewhere appears in the
  code.
- Paths are built with `File.join` and `File.expand_path`, never by string
  concatenation.
- The user directory takes precedence over the installation, for plugins,
  Recipes, databases and assets alike. Where a part of it is absent, the
  installation's own directory is the fallback.
- `scaffold` creates and never overwrites. `unscaffold` removes the whole user
  directory and is the one destructive operation the framework offers; it is not
  extended, and nothing else acquires the ability to delete an operator's data.
- A plugin writes only where its settings tell it to.

### 1.10 Network access

- **The framework reaches nothing.** No update check, no telemetry, no
  phone-home. Every request is a plugin's, on a Recipe's instruction.
- HTTPS is used wherever the service offers it. A plugin that still uses plain
  HTTP is a defect to be recorded, and one that sends a credential over plain
  HTTP is recorded as such in [`PLUGINS.md`](PLUGINS.md).
- **TLS certificate verification is never disabled.** There is no acceptable
  reason, and a plugin that did it has been corrected.
- A plugin that fetches repeatedly from one host supports `interval` and its
  documentation says to set it. Scraping politely is a requirement, not a
  courtesy.
- A URL that comes from a setting or from feed content is escaped before use,
  and is never interpolated into a shell command. An external command is run as
  an argument vector.
- **A URL that comes from feed content is external input.** It is fetched
  through `Automatic::Http`, which restricts the scheme to HTTP and HTTPS,
  because `URI.open` on such a string will read a local file as readily as an
  article.
- Every request has a connect and a read timeout. An unattended run that hangs
  is a failure mode with no upper bound on its cost.

### 1.11 Security and credentials

- **A Recipe is trusted local configuration**, equivalent to a shell script the
  operator wrote. This is the trust boundary, it is stated in
  `REQUIREMENTS.md` section 17, and it is the premise the following rules assume.
- Even so, YAML is loaded safely, so that a Recipe cannot name a Ruby class to
  instantiate. This costs nothing, since no Recipe needs it, and it removes a
  second and avoidable path to code execution. **Do not present this as making
  an untrusted Recipe safe**; the loader is not the boundary.
- Credentials are Recipe settings. That makes a Recipe holding them a secret
  file, which the documentation says plainly rather than glossing over.
- No credential in the repository: not in an example Recipe, not in a fixture,
  not in a test, not in a comment. The example Recipes in `config/` need none.
- No credential in the log, in an exception message, or in a pipeline item.
- No credential in CI. A test that needs one is not part of the default suite.
- A change that touches authentication says in its `VERSIONS` entry what it
  changed.

### 1.12 Judging a change

- Does it keep the Recipe format and the plugin contract, and if not, is that
  deliberate and recorded?
- Does it respect the direction of dependency?
- Does it leave the framework the small part?
- Does it keep a plugin's dependency out of everyone else's installation?
- Is it the smallest change that does the job?
- Does a test say it works, and does the default suite still need no network?
- Do the documents still match the code, in the same commit?

---

## 2. Ruby Policy

### 2.1 Style

The prevailing style of this repository is what a change matches. It is not
current fashion and that is deliberate: a change written in a different style
makes a diff harder to read than the style saves.

- Two-space indentation. No tabs. No trailing whitespace. A newline at end of
  file.
- Single quotes for a plain string, double quotes when interpolating.
- `snake_case` for methods and variables, `CamelCase` for classes, `SCREAMING_
  SNAKE_CASE` for constants.
- Braces for blocks are the established idiom here, including multi-line blocks,
  and were chosen to avoid stacked `end`s. Existing code is left as it is. New
  code may use either; matching the surrounding file matters more than the
  choice.
- Lines around 100 columns. Not enforced, and not a reason to reformat.
- Prefer a guard clause to a wrapping `unless`, in new code.

### 2.2 Scope of a change

- **Do not reformat a file you are not otherwise changing.** A large diff hides
  the change inside it.
- Do not rename a class, a method or a setting because the name is dated. The
  names in this repository are domain vocabulary: Recipe, pipeline, plugin,
  subscription, publish. They stay.
- Do not restructure a plugin while fixing it. A compatibility fix and a rewrite
  are two changes.
- Where a file is being substantially changed anyway, bringing it to the current
  style is fine.

### 2.3 File headers

Every Ruby file carries a header comment. Values start in the same column,
using `Source Code::`, the longest label, as the alignment baseline. Fields
appear in the order shown below. An executable uses this canonical form:

```ruby
#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Name::        automatic
# Author:       id774 (More info: http://id774.net)
# Source Code:: https://github.com/id774/automaticruby
# License::     The GPL version 3, or LGPL version 3 (Dual License).
# Contact::     idnanashi@gmail.com
# Created::     Feb 18, 2012
# Updated::     Aug 14, 2026
# Copyright::   Copyright (c) 2012-2026 Automatic Ruby Developers.
```

- Only files directly invoked as executables carry the shebang. Libraries,
  plugins and specs omit the shebang and otherwise use the same form.
- `Name` is the fully qualified name of what the file defines.
- `Author` records the author or authors established by the file and its Git
  history. The former name `774` is normalized to `id774`; third-party authors
  are never removed or replaced, and multiple authors retain their recorded
  order. Names and URLs are not inferred when the history does not provide them.
- The labels are exactly `Name::`, `Author:`, `Source Code::`, `License::`,
  `Contact::`, `Created::`, `Updated::` and `Copyright::`.
- `Created` is never changed.
- `Updated` is set to the date of a change that affects behaviour. A
  documentation-only or formatting-only change does not touch it.
- The project-level copyright notice is `Copyright (c) 2012-2026 Automatic
  Ruby Developers.` Explicit third-party copyright notices are preserved and
  are not inferred from the `Author` field.
- The `License` line records the GPLv3 or LGPLv3 dual license and matches
  [`LICENSE.md`](LICENSE.md).
- A `Description::` line may be added below `Name` when the file's purpose is
  not obvious from its name. New plugins should have one.
- The magic encoding comment is redundant on the supported Rubies. It is left in
  place in existing files, because removing it from forty files is a diff with
  no benefit, and it is not required in a new file.

Files do not carry a per-file version history. This repository versions at the
repository level only; see section 10.

### 2.4 Ruby version compatibility

- The supported range is stated in one place, `automatic.gemspec`
  (`required_ruby_version`), and the README and the documents agree with it. The
  set CI validates is a narrower statement and lives in the matrix; section 11
  says how the two relate.
- **Compatibility is written in the range's common API.** Where a Ruby release
  deprecates or removes something, the replacement chosen is the one that works
  unchanged on every supported version. `URI::Parser#escape` becoming obsolete
  is answered by naming `URI::RFC2396_Parser`, which means the same thing on all
  of them — not by a `RUBY_VERSION` branch.
- **A `RUBY_VERSION` conditional is a last resort**, for a difference that has
  no common expression. Two implementations of one behaviour cost more than the
  compatibility they buy: the branch not taken is the branch not tested.
- **Code for an unsupported Ruby is removed, not kept for safety.** A
  `RUBY_VERSION` comparison against 1.8 or 1.9, a branch for an interpreter that
  cannot install the dependencies, and a shim for a method that has been in core
  for a decade are all deleted.
- Nothing is written against a feature newer than the floor.
- A method removed by Ruby is replaced by its supported equivalent, and that is
  a compatibility fix rather than a refactor: `Kernel#open` on a URL becomes
  `URI.open`, `File.exists?` becomes `File.exist?`.
- **A library leaving the standard library is not by itself a reason to declare
  it.** Ruby moves libraries to default and then to bundled gems as it goes.
  Each one is judged on what actually requires it: the framework's own
  requirement becomes a runtime dependency, a plugin's becomes an optional one
  (section 9.1), and a requirement left over from code that no longer uses it is
  deleted.

### 2.5 Requiring

- The framework requires only what the framework uses. A plugin's library never
  appears in `lib/`.
- A plugin requires its libraries at the top of its own file.
- A library needed only by an optional path is required inside that path, so the
  plugin loads without it. The S3 branch of `StoreFile` is the example.
- The CLI requires a subcommand's libraries inside that subcommand, so a
  command that does not use `feedbag` or the OPML parser does not load them.
- **An optional gem is required through `Automatic.require_optional`**, which
  names the gem, what needed it and how to install it when it is absent. A bare
  `require` of an optional gem answers a solvable problem with
  `cannot load such file`, which is not the framework's best answer.
- **`Bundler.require` is not how the framework loads its dependencies.** An
  installed library must not impose a bundle on the program requiring it. The
  Bundler setup in `environment.rb` is a convenience for a source checkout and
  does nothing when there is no `Gemfile`.

---

## 3. Plugins

- A new plugin follows [`PLUGINS.md`](PLUGINS.md) section 3, which is the
  contract, and section 3.10, which says which category it belongs in.
- **Converting the pipeline into some other representation is a `Publish`
  plugin's work, and the result stays inside the plugin.** It is serialized at
  the boundary, written to the destination, and never passed along the pipeline
  or made known to the framework, which keeps Invariant 2 and section 1.5
  intact. Producing a portable document — one a person can read, ordinary tools
  can process and another program can be given, with no service behind it — is
  a destination like any other and belongs in that category.
- A new plugin is added to the catalogue in `PLUGINS.md` section 6 in the same
  change, with its settings table and its status.
- A new plugin comes with a spec that reaches no network.
- A plugin's dependency is not added to the gemspec's runtime dependencies; see
  section 9.
- A change to an existing plugin does not change what an existing Recipe means
  unless that is the point of the change.

---

## 4. The life of a plugin

Plugins outlive the services they talk to. The policy for what happens then:

- **A shipped plugin has a current practical use.** That is the condition for
  being in the gem, and it is a condition that has to keep being met, not one
  met once. Having been useful is not the test.
- **A plugin is classified, in `PLUGINS.md` section 6**, as Supported, Supported
  (external) or Needs rework, with the reason. There is no status meaning
  "does not work and never will"; a plugin in that position is removed.
- **A dead integration is never faked into life.** No stub of a shut-down
  service, no mock that makes an integration look alive, no test that asserts
  against a simulation. This is Invariant 7 and it has no exceptions. If a
  plugin can only be made to look supported by simulating what it talks to,
  what it needs is deletion, not a double.
- **Unsupported code is not kept for preservation.** Git history holds every
  implementation this project ever shipped, and holds it without installing it
  on anyone's machine or listing it in a catalogue an operator reads for
  guidance. A plugin retained only so that its code exists somewhere is
  retained for a reason the version control system already covers.
- **The judgement is evidenced.** "Nobody uses that any more" is not a reason.
  The service's own site, its API documentation or its published shutdown
  notice is, and the reason goes in the catalogue entry or in the removal
  record. Where the evidence cannot be obtained, the plugin is classified
  **Needs rework** and kept: the failure mode of guessing is deleting something
  that works.
- **Needs rework means restoration is realistic.** A capability the service
  still offers, reachable by a current API, with the work amounting to a
  migration rather than a new project. A plugin whose service is gone is not
  Needs rework; it is removed.
- **Restoring a plugin to a service's current API** is a separate change, one
  plugin at a time, with the catalogue entry updated in the same commit. Where
  the current API forces a credential format the old Recipe cannot express,
  that is a breaking change and is documented as one rather than hidden behind
  a translation.
- **Removing a plugin removes all of it**: implementation, specs, example and
  integration Recipes, catalogue entry, and any optional dependency nothing
  else needs. A class left behind to raise "this no longer works" is not a
  courtesy; the loader's `NoPluginError` says the same thing earlier and
  without shipping code.
- **A removal is recorded in `VERSIONS`** in enough detail that an operator
  whose Recipe breaks can find out why, and the reasons are kept in
  `PLUGINS.md`. Removals are batched into a release rather than trickled, so
  that an upgrade has one list to read.
- **A modernized plugin keeps its Recipe's meaning.** Class names, setting
  names and defaults are not changed for tidiness; where a fix makes a plugin
  behave as its documentation always said it did, that is still a behaviour
  change and the catalogue entry says so.
- **A Supported plugin has deterministic local tests.** They cover this side of
  the boundary — settings, request construction, serialization, response
  handling, error behaviour — and reach no network, need no credential and
  require no running service. The availability of somebody else's API is not
  something a unit test can assert and is not something required CI waits on.

---

## 5. Testing

- **RSpec**, under `spec/`, mirroring the source tree: `spec/lib/` for the
  framework and `spec/plugins/<category>/` for plugins.
- **The default suite reaches no network and needs no credential.** This is
  Invariant 6. A spec that would is not written; the integration Recipes under
  `test/integration/` are where that belongs, and they are run by hand.
- A framework spec covers the loader, the Recipe, the pipeline, the log and the
  CLI's exit statuses.
- A plugin spec constructs the plugin with a `config` and a pipeline built by
  `AutomaticSpec.generate_pipeline`, calls `run`, and asserts on the result.
- **An example that reaches a real host is tagged `:network`** and is excluded
  from the default suite and from CI. It is kept, because it is a real test and
  is the way to check a plugin against the service it talks to, and it is run
  deliberately with `AUTOMATIC_NETWORK_SPECS=1`. Several of these point at hosts
  that no longer serve what they expect, which is a further reason not to make
  them a gate. A new example that reaches a host is tagged; one that does not is
  never given the tag to make a failure go away.
- **The default suite does not depend on an optional plugin gem.** A gem the
  `Gemfile` declares in an optional group is not installed by `bundle install`,
  so the plugins that need it are not verified by the default suite or by the
  required workflow. That is a decision, taken here, and not something a failure
  discovers: the gems it applies to are the declared list
  `AutomaticSpec::OPTIONAL_PLUGIN_GEMS`, a spec whose plugin needs one guards
  its file with `AutomaticSpec.optional_dependency?`, and naming a gem that is
  not on the list raises rather than skipping. Selecting the group with
  `bundle config set --local with plugins` and installing runs those specs as
  part of the ordinary suite.
- **A guard is a skip with a reason, not a `pending`.** A spec outside the
  default suite prints why it is outside it and does not run; the default
  suite's output is a list of what was verified rather than a list of what was
  not.
- A spec whose plugin's gem is not installed is skipped by
  `AutomaticSpec.plugin_available?`, which names the missing gem. That is the
  intended behaviour and is not worked around by faking the gem.
- **The default suite is kept small and reliable rather than large.** It reaches
  no network, needs no credential, needs no external daemon, writes outside no
  temporary directory of its own, redirects `HOME`, and does not depend on
  filesystem ordering, on the clock or on a random seed. A test that cannot be
  made repeatable does not belong in it. Guaranteeing fewer things reliably is
  the better trade, and it is not the same as weakening a test: `|| true`,
  `continue-on-error` and a rescue that swallows a failure are forbidden, and
  the tests that remain are held strictly.
- **A spec does not write outside its own temporary directory.** Where a plugin
  resolves a path under the home directory, the spec redirects `HOME` to a
  temporary directory rather than operating on the developer's real
  `~/.automatic`.
- Coverage is measured with SimpleCov when `COVERAGE=on`, and is not a gate. The
  historical `rcov` and `simplecov-rcov` tooling has been removed; it existed
  for Ruby 1.8 and for a CI server that no longer runs.
- `rake spec` runs the suite; `rake spec:lib` and `rake spec:plugins` run the
  halves. `rake` alone runs `spec`.
- CI runs `bundle install` and `rake spec` on every supported Ruby version, and
  nothing that needs a secret.

---

## 6. Command line

- **The CLI is a library**, `Automatic::CLI`, and `bin/automatic` is a process
  entry point that does nothing but call it and exit with its result.
- `CLI.run` returns an `Integer` and never calls `exit`, so the command line is
  unit-testable.
- Exit statuses are fixed: `0` did the work or printed help or version, `1`
  failed or nothing was asked for, `2` the command line was rejected.
- `--help` and `--version` exit `0` and print to standard output.
- Option parsing uses `optparse` from the standard library. **No CLI framework
  is introduced**; the interface is one option and seven subcommands, and a gem
  for that would be a dependency for nothing.
- The subcommands and the meaning of `-c` are part of the compatibility promise.
  Adding a subcommand is fine; removing or renaming one is a breaking change.
- A subcommand prints its result to standard output, because printing is what it
  is for.

---

## 7. Backward compatibility

What this repository promises not to break, absent a deliberate and recorded
decision:

| Interface | Promise |
| --- | --- |
| Recipe format | A Recipe that worked keeps working |
| Plugin contract | `new(config, pipeline)` and `run` |
| Plugin naming | The class-name-to-file-path rule |
| User directory | `~/.automatic` and its four subdirectories |
| User plugin precedence | The user directory shadows the installation |
| CLI | `-c`, the subcommand names, and the exit statuses |
| Store databases | Existing SQLite files stay readable |
| Gem name | `automatic`, providing the `automatic` executable |

Breaking one of these is a decision, taken deliberately, recorded in
[`VERSIONS`](VERSIONS) in terms an operator can act on, and never a side effect
of a clean-up. Adding an optional setting whose default preserves current
behaviour breaks nothing.

---

## 8. Documentation

- **Documentation is updated in the same change as the behaviour it describes.**
  A behaviour change with no documentation change has not been finished.
- The documents divide as follows, and one fact has one home:

  | Document | Holds |
  | --- | --- |
  | `README.md` | The entry point: what it is, how to install and run it, where everything else is |
  | `doc/REQUIREMENTS.md` | What the system is for and what it guarantees |
  | `doc/BASIC_DESIGN.md` | How it is composed |
  | `doc/PLUGINS.md` | The Recipe format, the plugin contract, the plugin catalogue |
  | `doc/POLICY.md` | This document: how a change is made and judged |
  | `doc/DEPLOYMENT.md` | Installing, running and operating it |
  | `doc/VERSIONS` | Release history |
  | `doc/LICENSE.md`, `doc/COPYING`, `doc/COPYING.LESSER` | The licence |
  | `doc/AUTHORS` | Contributors |

- **No cross-repository reference.** These documents never say "see the policy
  of another repository", or "as in *X*". Everything needed to understand,
  build, run and change this repository is here. Another repository may be a
  useful reference while working, and it is not a citation.
- **Documents are in English**, as are code, comments and commit messages.
  Japanese appears only where it is data: a search keyword in an example, a
  broadcast station name in a plugin's settings.
- Markdown documents may assume a renderer. `VERSIONS`, `COPYING`, `COPYING.LESSER` and `AUTHORS`
  are plain text and keep their extensionless names, which are the names they
  are published and linked under.
- Prose wraps near the width the document already uses. `VERSIONS` follows
  section 10.4 instead.
- **A document is not deleted for being old.** It is deleted when its content
  has been moved somewhere that is now the source of truth, and the move is
  recorded in `VERSIONS`.

---

## 9. Dependencies

### 9.1 The split

Install the core by default; install a plugin's dependencies only when they are
needed. Dependencies fall into three groups, and which group a gem is in is a
decision, not an accident:

**Runtime dependencies** — declared in `automatic.gemspec`, installed by `gem
install automatic`. A gem is here only if a file in `lib/` requires it: what
`require 'automatic'`, loading a Recipe, loading a plugin, running a pipeline
and the command line itself need, and nothing more. A gem that reached this list
because of a plugin, because a plugin no longer uses it, or because a Ruby
release moved a library out of the standard library, is moved back out.

**Optional dependencies** — used by one plugin or a few, required inside the
plugin's own file, declared in an optional group of the `Gemfile`, and **not
declared as runtime dependencies**. An operator who uses that plugin installs
the gem. This is Invariant 4, and it is why installing this gem does not install
an AWS SDK.

The permanent rules of the split:

- **A core dependency is one the framework itself has.** A plugin's dependency
  is never a framework runtime dependency, however useful, popular or
  Supported that plugin is. How many Recipes happen to use it is not the test;
  what `lib/` requires is.
- **The operator who uses the plugin installs its gem.** Not having it must
  never stop the framework from starting, and a Recipe that does not name the
  plugin must run without it.
- **A new plugin does not increase the core dependencies.** Adding one to the
  runtime list needs an architectural justification — the framework itself
  came to need the gem — recorded with the change; wanting the plugin to work
  out of the box is not one.
- **The default tests and required CI do not depend on an optional
  integration.** Being in this group has that intended consequence: those
  plugins are not part of what a green build guarantees. See section 5.
- **An unsupported or optional integration does not decide a framework-wide
  dependency.** Where one plugin needs a gem, that gem is the plugin's.

A missing optional gem is reported, not merely raised: the plugin requires it
through `Automatic.require_optional`, which names the gem, what needed it and
how to install it. That helper is the whole of the mechanism, and no dependency
manager, plugin manifest or resolver is introduced beyond it.

**Development dependencies** — the test and build tooling.

### 9.2 Adding, updating and removing

- A gem is added when something committed here uses it, and the commit says
  which plugin and why.
- **Dependencies are not raised in bulk.** Each is updated for a reason —
  a security fix, a Ruby compatibility requirement, an API this repository
  needs — and the code that uses it is checked against the new version. Bumping
  everything to latest and then repairing what broke is not how this is done.
- Version constraints are ranges wide enough not to conflict with the rest of an
  operator's bundle, and tight enough to exclude a major version this code has
  not been checked against.
- A gem no longer used by anything committed here is removed.
- A gem whose service no longer exists is removed, along with the plugin that
  needed it; see section 4. An optional group left with nothing to install is
  deleted from the `Gemfile` in the same change.
- **Nothing is vendored.** Dependencies come from RubyGems, which keeps their
  licences theirs.

### 9.3 Sources

- One gem source: `https://rubygems.org`.
- **No plain-HTTP source, ever.** `http://rubygems.org` in a `Gemfile` is a
  defect, not a style question.
- No source that has shut down. `gems.github.com` has not existed since 2014 and
  is not to reappear.

### 9.4 Packaging

- The gemspec is **hand-maintained**. It was generated by Jeweler, which is no
  longer maintained and which required its own Rake tasks and a `VERSION` file
  to regenerate a file that is easier to simply edit. The generator is gone; the
  file is now source.
- The gemspec states `required_ruby_version`, the licence, the homepage, the
  source code URL and the metadata links, and its `files` list is derived from
  what Git tracks so that it cannot drift.
- The `Gemfile` declares the source and evaluates the gemspec, so that runtime
  dependencies are stated once. Development and optional gems are groups in the
  `Gemfile`.
- `Gemfile.lock` is not committed. This is a library, and locking would impose a
  resolution on every consumer.
- `Rakefile` carries the test tasks and nothing else. It is not a build system,
  and no build system is introduced.
- A release requires green required CI. Its built gem is inspected and installed
  locally before publication, and its source version and metadata must agree.
- A published version is immutable. Credentials are never committed, and
  release commits and tags are not rewritten to conceal a publication error.
- The manual publication procedure is [`RELEASING.md`](RELEASING.md). Publishing
  is an explicit maintainer action, not a side effect of a build or test task.

---

## 10. Versioning

### 10.1 Scheme

Releases are numbered `<year>.<month>`, two digits each, taken from the release
date. This is the scheme the project has used since its first release in
February 2012, it mimics Ubuntu's, and it does not change.

```text
26.08      a release made in August 2026
26.08.1    a release correcting 26.08, in the same month
```

A third `<patch>` level is appended only when a release corrects an earlier one
without accumulating a month's work. `14.12.1` and `14.12.2` are historical
examples.

The number carries no compatibility meaning. A month is not a major version, and
a compatibility break is signalled by what the `VERSIONS` entry says, not by the
number.

### 10.2 Where the version is written

The release version appears in three places, which are changed together in one
commit:

| Place | Form |
| --- | --- |
| `VERSION` | `26.08` |
| `lib/automatic/version.rb` | `Automatic::VERSION` |
| `doc/VERSIONS` | The entry heading |

`automatic.gemspec` reads `VERSION`, and `automatic --version` prints
`Automatic::VERSION`, so neither is a separate place to update.

Historically `lib/automatic/version.rb` carried a `-devel` suffix between
releases while `VERSION` did not, and a spec asserted the exact string. That
divergence is not continued: the two agree, and the spec asserts that they
agree rather than asserting a literal.

### 10.3 What is a release

- **Work that is not released yet takes no version of its own.** It belongs to
  the entry already standing at the top of `doc/VERSIONS`.
- An unreleased entry carries `(Release Date: TBD)`. Replacing that with the
  date is the release itself, and is not a change to record inside the entry.
- **A repository that has not yet made its first release is in its initial
  construction stage**, and that stage takes no entry here. The work of building
  up to the first release is not accumulated in `doc/VERSIONS` one by one: the
  file is the record of released versions, not of the construction that precedes
  the first of them, and its first entry is written when that release is made.
- **A series of changes made on one day is one version**, not several. Do not
  split a day's work across version numbers.
- **A version that actually existed is never merged into another**, even when it
  shares a date with one. `14.10.0` and `14.10.1` were both released on
  2014-10-23 and both stay.
- A documentation-only change takes no entry unless its scale makes it worth one
  line saying so.
- Git tags carry the release version, and are created only when a release is
  made.

### 10.4 How `doc/VERSIONS` is written

`doc/VERSIONS` is a version-level summary of what each release changed. It is
not a transcription of the commit log: the commits record how the work happened,
the version history records what it amounts to.

- Record externally meaningful or architecturally significant outcomes, such
  as compatibility, security, public interfaces, major features, packaging,
  licensing, documentation architecture and test strategy.
- Omit development-time corrections, implementation details and intermediate
  states that were reverted or superseded before release. Git history retains
  that process.
- Summarize related low-level changes under their substantive outcome instead
  of listing each method, dependency, test or file separately.

- Each entry opens with `vX.YY (YYYY-MM-DD)`, or `vX.YY (Release Date: TBD)`
  while unreleased, underlined with `-`, followed by one `-` bullet per change.
  Newest first. UTF-8.
- **One coherent change is one bullet on one physical line.** The entry is a
  list meant to be scanned, and a wrapped bullet costs it that: the eye no
  longer finds the changes by counting lines, and a diff no longer shows one
  added line per added change.
- This is a deliberate exception to the wrapping the other plain text documents
  follow. Do not rewrap `doc/VERSIONS` to 80 columns, and do not report a long
  bullet there as a defect.
- Aim for about 100 columns. A bullet carrying file names, module names, setting
  names or plugin names may run to about 120, or past it when the names it needs
  are that long. These figures prompt a reread, they are not a limit to enforce.
  A bullet that is long because the change is long is correct.
- **When a bullet runs long, abstract it; never break it across lines.** Drop
  the implementation detail, the example, the reason and the secondary effect,
  and state what the change is. Keep what a reader cannot reconstruct without
  it: what changed, what is now observably different, what it does to
  compatibility, what it does to security, and the identifiers someone would
  search for.
- Changes serving one purpose are described together even when they touch
  several files. Related changes to one file within a version are normally one
  bullet. Changes to one file carrying independent meaning are not forced
  together — coherence decides, not the file name.
- Entries touching the same file, plugin or feature are placed near each other,
  so that a version reads as a coherent whole. An independent change belonging
  with nothing already listed is appended to the end of the current entry.
- Order within a version serves the reader, not the commit history.
- Released entries retain their substantive history even when their wording or
  level of detail predates these rules.
- `doc/VERSIONS` carries these guidelines again at its foot.

### 10.5 The historical record

- **Past entries and their dates are not rewritten**, not to correct their
  wording, not to renumber them, and not to make them consistent with this
  document's current rules. They are the record of what was released.
- The release history was previously kept in `doc/ChangeLog`. It has been moved
  into `doc/VERSIONS` in full, and `doc/ChangeLog` is gone; the two documents
  had the same responsibility and keeping both meant keeping two records that
  would diverge. No entry and no date was changed in the move.
- Where the record is incomplete — releases with no tag, or a version bumped
  with no entry — `VERSIONS` says so rather than inventing an entry.

---

## 11. Continuous integration

- CI runs on GitHub Actions. `.github/workflows/ci.yml` is the required check;
  `.github/workflows/plugins.yml` is a separate, non-required workflow that
  installs the optional `plugins` group and runs the same suite, so that the
  documented all-plugins setup is checked as well as described.
- **CI validates representative supported Ruby versions rather than every
  intermediate release.** The matrix runs the ends of the supported range and
  the release in the middle. The matrix and `required_ruby_version` are
  therefore *not* the same set, and neither is wrong: the gemspec states what
  the code is written for, the matrix states what is checked on every commit.
  [`REQUIREMENTS.md`](REQUIREMENTS.md) section 20 states both.
- Removing a version from the matrix is not a statement that it fails, and no
  incompatibility is introduced to make it one.
- What CI does is: install the bundle, build the gem, load the library, run the
  command line, run the default suite. It is deliberately short, and an optional
  integration is not added to it.
- **CI holds no secret and reaches no external service.** No credential is
  configured, and no integration test against a third-party API is run there.
- **The required workflow installs no optional plugin gem**, so no plugin's own
  dependency is a condition of the check that gates a change. The minimal
  configuration is what it runs, which is what keeps the split of section 9.1
  honest over time. Where an optional integration is worth testing at all, it is
  tested separately from the required workflow; section 5 says how.
- **A non-required workflow is held to the same standard as the required one.**
  It is separate so that an optional dependency cannot gate a change, not so
  that it may fail quietly.
- **A failure is fixed, not silenced.** `|| true`, `continue-on-error` and a
  step that hides its exit status are not how a build is made green. Narrowing
  what is guaranteed is a legitimate answer; pretending to guarantee it is not.
- The Jenkins instance the project used until 2015 is gone. References to it
  have been removed and are not to be reintroduced.
- A red build is fixed or reverted. It is not left red.
