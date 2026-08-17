# Recipes and plugins

## 1. What this document is

This is the specification of the two things outside this repository that depend
on it: the **Recipe** format, which operators write, and the **plugin
contract**, which plugin authors implement. It also catalogues the plugins
shipped in the gem, with what each one accepts and whether it still works.

The system these two interfaces belong to is described in
[`REQUIREMENTS.md`](REQUIREMENTS.md); the machinery that implements them is in
[`BASIC_DESIGN.md`](BASIC_DESIGN.md); the rules for changing them are in
[`POLICY.md`](POLICY.md).

It stands on its own. Nothing in it is completed by a document kept in another
repository.

Plugin authors can start with the complete user-plugin example in
[`PLUGIN_DEVELOPMENT.md`](PLUGIN_DEVELOPMENT.md).

---

## 2. The Recipe

### 2.1 What a Recipe is

A Recipe is a YAML file describing one job: which plugins run, in what order,
and with what settings. It is the whole of the job's definition — there is no
other configuration file and no environment to set.

```sh
automatic -c ~/.automatic/config/example/feed2console.yml
```

### 2.2 Structure

```yaml
global:                       # optional
  log:
    level: info               # info | warn | error | none

plugins:                      # required
  - module: SubscriptionFeed  # required
    config:                   # optional
      feeds:
        - https://example.com/feed

  - module: FilterIgnore
    config:
      link:
        - example.net

  - module: PublishConsole    # a plugin needing no settings omits config
```

The document is a mapping with two keys at the top level.

### 2.3 `plugins`

A sequence of plugin entries, run in the order written. Required: a Recipe with
no `plugins` sequence is refused with `Automatic::InvalidRecipeError`.

Each entry is a mapping:

| Key | Required | Type | Meaning |
| --- | --- | --- | --- |
| `module` | yes | string | The plugin class name, in CamelCase |
| `config` | no | mapping | Passed to that plugin and read by nothing else |

- `module` names a class in `Automatic::Plugin`. How the name is resolved to a
  file is section 3.2. A name that resolves to nothing raises
  `Automatic::NoPluginError` **before any plugin runs**, so a typo costs
  nothing.
- `config` is handed to the plugin untouched. The framework does not validate
  it, does not apply defaults to it and does not know what any key means. What
  a given plugin accepts is section 6.
- An entry may name the same module more than once. Two `FilterIgnore` entries
  with different keywords is ordinary use.

### 2.4 `global`

Optional, and almost empty on purpose. One key is read:

| Key | Values | Meaning |
| --- | --- | --- |
| `global.log.level` | `info`, `warn`, `error`, `none` | The log threshold for this run. Default `info`. |

`global.timezone` and `global.cache` appear in the example Recipes and in
Recipes written years ago. **Nothing reads them.** They are inert, they are kept
so that existing Recipes are not edited for no reason, and they are recorded
here so that no one gives them a meaning by accident. A Recipe that sets them
behaves exactly as one that does not.

An unrecognised key anywhere in `global` is ignored.

### 2.5 How `-c` is resolved

The value of `-c` is looked for in `~/.automatic/config` first, and used as a
path as given if it is not there:

```sh
automatic -c blog.yml            # ~/.automatic/config/blog.yml, if it exists
automatic -c ./recipes/blog.yml  # otherwise, exactly this path
automatic -c /etc/automatic/blog.yml
```

A path that resolves to nothing fails with the exit status `1` and a message
naming the file.

### 2.6 Types

Recipe values are ordinary YAML scalars, sequences and mappings, and the
framework loads them **safely**: a Recipe may not name a Ruby class to
instantiate, and a document that tries to is refused. YAML aliases are
permitted, so a block of settings can be shared:

```yaml
plugins:
  - module: SubscriptionFeed
    config: &retrying
      retry: 3
      interval: 5
      feeds:
        - https://example.com/feed

  - module: StoreFile
    config:
      <<: *retrying
      path: /var/tmp/automatic
```

Note what the plugins do with types, because it is not always what YAML implies:

- `retry` and `interval` are read through `to_i`. An absent value is `0`, which
  means one attempt and no pause. A quoted `"3"` and a bare `3` behave alike.
- Keyword lists (`link`, `title`, `description`) are sequences of strings, and
  matching is a **substring** test, not a pattern and not a whole-word match.
  An empty string therefore matches everything, which is a way to drop
  everything and is occasionally used deliberately.
- Booleans are usually spelled `1` and `0` rather than `true` and `false`, and
  the plugins that do this compare against `1` exactly. This is inherited and is
  noted per plugin in section 6.

### 2.6.1 Setting names that collide

The Recipe is wrapped in `Hashie::Mash`, which is what lets a plugin entry answer
to `plugin.module` and `plugin.config`. The cost is that a setting name which is
also a method of `Hash` or `Enumerable` — `count`, `first`, `key`, `max`, `min`,
`select`, `size`, `sort`, `zip` — makes it log a warning on every run:

```text
You are setting a key that conflicts with a built-in method Hashie::Mash#sort
defined in Enumerable. This can cause unexpected behavior when accessing the
key as a property. You can still access the key via the #[] method.
```

The value is stored and is read correctly, because plugins read their settings
by string key rather than as a property. This is noise, not breakage, and a
Recipe using such a key needs no change.

Two shipped plugins have such a name, from before this was understood, and they
keep it: `FilterSort`'s `sort` and `PublishMemcached`'s `key`. Renaming them
would break every Recipe using them, which is not a trade worth making for a
warning. **A new plugin should not introduce one**: prefer `max_length` to
`max`, `item_count` to `count`, `cache_key` to `key`.

### 2.7 Failure

| Situation | Result |
| --- | --- |
| The file does not exist | Exit `1`, the path is named |
| The file is not valid YAML | Exit `1`, the parser's message is shown |
| The document is not a mapping | `Automatic::InvalidRecipeError`, exit `1` |
| No `plugins` sequence | `Automatic::InvalidRecipeError`, exit `1` |
| `module` names an unknown plugin | `Automatic::NoPluginError`, exit `1`, nothing has run |
| A plugin raises during `run` | The run ends there. Exit `1`. Earlier plugins' effects stand. |

The last row is the one to design Recipes around: there is no rollback and no
resume. A Recipe that must not repeat its effect on the next run puts a store
plugin in front of the plugin with the effect. See
[`REQUIREMENTS.md`](REQUIREMENTS.md) section 12.

### 2.8 Compatibility

A Recipe that worked with an earlier release keeps working. Recipes live outside
this repository and cannot be migrated by it, so removing a key, renaming a key,
changing a default so that an unchanged Recipe does something else, or changing
how a value is interpreted are breaking changes. They are made deliberately and
recorded in [`VERSIONS`](VERSIONS). Adding an optional key whose default
preserves current behaviour is not one.

---

## 3. The plugin contract

### 3.1 The whole of it

A plugin is a Ruby class in the `Automatic::Plugin` namespace that can be built
with two arguments and answers one method:

```ruby
module Automatic::Plugin
  class FilterExample
    def initialize(config, pipeline = [])
      @config   = config
      @pipeline = pipeline
    end

    def run
      # ... work ...
      @pipeline
    end
  end
end
```

- `config` is the entry's `config` mapping, or `nil` when the entry had none.
  **A plugin that can be used without settings must tolerate `nil`.**
- `pipeline` is the value returned by the previous plugin, or `[]` for the
  first.
- `run` returns the pipeline for the next plugin. Its return value is the whole
  of its output to the framework.

There is no `setup`, no `teardown`, no registration call, no base class and no
mixin to include. A class with those two methods, in a file the loader can find,
is a plugin.

### 3.2 Naming and location

The class name and the file path are the same fact written twice, and the loader
converts between them:

```text
Automatic::Plugin::SubscriptionFeed
                   |
                   | underscore
                   v
              subscription_feed
                   |
                   | split on the category directory name
                   v
          subscription / feed.rb
```

So the rules are:

- The class name is `CamelCase` and begins with its category: `Subscription`,
  `CustomFeed`, `Filter`, `Store`, `Provide`, `Notify` or `Publish`.
- The file is `<category>/<rest>.rb`, where both parts are `snake_case`.
- The file defines exactly that class, inside `module Automatic::Plugin`.

Examples, including the ones that are easy to get wrong:

| Class | File |
| --- | --- |
| `SubscriptionFeed` | `subscription/feed.rb` |
| `FilterAbsoluteURI` | `filter/absolute_uri.rb` |
| `CustomFeedSVNLog` | `custom_feed/svn_log.rb` |
| `PublishHatenaBookmark` | `publish/hatena_bookmark.rb` |
| `FilterDescriptionLink` | `filter/description_link.rb` |

The category directory is not decoration: it is half of the lookup key. A file
in a directory whose name is not a prefix of the underscored class name is never
found.

### 3.3 Discovery and precedence

Two search roots, in this order:

1. `~/.automatic/plugins/<category>/<rest>.rb`
2. `<installation>/plugins/<category>/<rest>.rb`

The first match wins, so **a plugin in the user directory shadows a shipped
plugin of the same name.** That is the supported way to change a shipped
plugin's behaviour without editing the installation.

Creating a new category is creating a directory. `~/.automatic/plugins/mine/`
plus a class named `MineSomething` works with no change to the framework, though
staying inside the seven categories is preferred, because their names tell a
reader where in a pipeline the plugin belongs.

Loading is lazy: the loader registers an `autoload`, so the file is read when
the constant is first used. A syntax error in a plugin therefore surfaces when
that plugin's entry is reached, not when the Recipe is loaded.

### 3.4 The pipeline value

Everything a plugin receives and returns has one shape:

> an `Array` of feed objects, where a feed object answers `#items`, and an item
> answers `#title`, `#link`, `#description`, `#date`, `#author`, `#comments`,
> `#source`, `#enclosure` and `#content_encoded`.

The elements are RSS objects, from `RSS::Parser` or built by `RSS::Maker`. A
plugin whose source is not a feed converts it, and `Automatic::FeedMaker` is how:

```ruby
items = rows.map do |row|
  Automatic::FeedMaker.generate_feed(
    'title' => row[:title], 'url' => row[:url], 'description' => row[:body]
  )
end
@pipeline << Automatic::FeedMaker.create_pipeline(items)
@pipeline
```

`FeedMaker.generate_feed` takes a hash with any of `title`, `url`,
`description`, `author`, `comments` — note `url`, not `link` — and returns one
item. `FeedMaker.create_pipeline` takes a list of items and returns one feed
object. A plugin that produces items ends with those two calls.

Rules that follow from the shape:

- **Return the shape, always.** Returning `nil`, a string or a bare array of
  items ends the pipeline for everything after it.
- **`link` may be `nil`, and so may any other field.** Filters signal "not
  applicable" by setting `link` to `nil`, so a plugin that dereferences a field
  without checking will be handed `nil` sooner or later.
- **Guard the feed itself.** `@pipeline.each { |feeds| next if feeds.nil? }` is
  the prevailing idiom, because a subscription plugin that failed may have put a
  `nil` in the array.
- **A dropped item means a rebuilt feed.** RSS objects are not conveniently
  filtered in place, so a plugin that removes items collects the survivors and
  calls `FeedMaker.create_pipeline` on them.
- The field names are RSS names used for values that are not RSS. `title` may
  hold a weather condition. This is a known cost of one shape and it is
  accepted.

### 3.5 Settings

- Read from `@config`, by string key: `@config['interval']`.
- Assume nothing. `@config` itself may be `nil`, and any key may be missing.
- Follow the established names: `retry` for an attempt count, `interval` for
  seconds between attempts, `db` for a database file, `path` for a directory.
- Do not choose a setting name that is a method of `Hash` or `Enumerable`; see
  section 2.6.1.
- Do not read the environment, and do not read a file other than one named in
  the settings. The `config` mapping is the plugin's entire input besides the
  pipeline.

### 3.6 Errors, retrying and logging

A plugin owns its own transient failures. The shape used throughout:

```ruby
retries   = 0
retry_max = @config['retry'].to_i
begin
  # ... the attempt ...
rescue => e
  retries += 1
  Automatic::Log.puts('error', "ErrorCount: #{retries}, #{e.message}")
  sleep @config['interval'].to_i
  retry if retries <= retry_max
end
```

- **A failure is logged.** Whatever the plugin decides to do about an error, the
  log is the only record an unattended run leaves. Swallowing an error silently
  is a defect; so is logging it at `info`.
- **Raising is allowed, and it ends the run.** The framework does not catch
  plugin exceptions. Raise when continuing would be wrong; rescue when the
  Recipe should carry on with less data.
- **Log through `Automatic::Log`, not `puts`.** The exception is a plugin whose
  purpose is to write to the terminal, which holds an output object in an
  instance variable so that a test can substitute it.

### 3.7 Credentials

Credentials arrive as ordinary settings, which makes the Recipe holding them a
secret file. A plugin therefore:

- never logs a credential, and never logs `@config` wholesale;
- never writes one into a pipeline item, where a later publishing plugin would
  send it somewhere;
- verifies TLS certificates. Disabling verification is not acceptable, whatever
  a service's certificate is doing.

### 3.8 Dependencies

A plugin requires its own libraries at the top of its own file. A library that
ships with Ruby is required plainly; a gem the operator has to install is
required through `Automatic.require_optional`, which names the gem, the plugin
and the way to install it if it is absent:

```ruby
module Automatic::Plugin
  class PublishMemcached
    Automatic.require_optional('dalli', needed_by: 'PublishMemcached')
```

```text
The `dalli` gem is not installed. It is needed by PublishMemcached. Install it
with `gem install dalli`, or in a source checkout add its group to the bundle;
see the optional plugin dependencies in doc/DEPLOYMENT.md.
```

Pass `gem_name:` where the gem's name differs from the path required, as
`activerecord` does from `active_record`.

That is what keeps a gem needed by one plugin out of everyone else's
installation. A gem used by a single plugin is not added to the framework's
runtime dependencies; it goes in an optional group of the `Gemfile` and the
operator who uses the plugin installs it. See [`POLICY.md`](POLICY.md)
section 9.

A Recipe therefore needs the sum of what its plugins need, and each is loaded
when the pipeline reaches it, so a gem missing for the third plugin is reported
after the first two have run. [`DEPLOYMENT.md`](DEPLOYMENT.md) lists which
plugin needs which gem, and "Working out what a Recipe needs, in a checkout"
takes one Recipe through adding those up before running it.

Where a plugin has an optional capability that needs a heavier library — S3
support in `StoreFile`, for instance — the `require` goes inside the branch that
uses it, so the plugin loads and its ordinary path works without that gem
installed.

### 3.8.1 Fetching

A plugin that fetches over HTTP calls `Automatic::Http`:

```ruby
body = Automatic::Http.read(url)          # the body, or an exception
Automatic::Http.open(url) { |io| ... }    # the stream, for a caller that wants it
Automatic::Http.uri(url)                  # a validated URI, or an exception
Automatic::Http.fetchable?(url)           # for skipping an item rather than failing
```

`read` returns a string that `open-uri` has already applied an encoding to,
whether or not the response declared one: a page served as `text/html` with no
charset comes back tagged UTF-8 because that is the fallback, not because the
page said so. A plugin that hands the body to an HTML parser wants `open`
instead, because a parser given the stream reads the `meta` charset for itself
and a parser given the string believes the tag. `FilterFullFeed` is the worked
example; the difference there was a whole article in mojibake.

It is a helper and not a client: it opens the URL through `open-uri` with the
scheme restricted to HTTP and HTTPS, a connect and a read timeout, a bounded
redirect chain and this project named as the agent. A URL string carrying
characters a URI may not — a space, a Japanese query term — is escaped and
parsed again rather than raising.

The scheme restriction is the part that matters most: **a link in a pipeline
item comes from a feed, which is to say from outside.** `URI.open` on such a
string will read `file:///etc/passwd` as readily as an article.

### 3.9 Testing a plugin

Construct it, run it, assert on what came back:

```ruby
require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper')
require 'filter/example'

describe Automatic::Plugin::FilterExample do
  subject do
    described_class.new({ 'key' => 'value' },
      AutomaticSpec.generate_pipeline do
        feed { item 'https://example.com/a', 'A' }
        feed { item 'https://example.com/b', 'B' }
      end)
  end

  its(:run) { should have(1).feeds }
end
```

`AutomaticSpec.generate_pipeline` builds a pipeline; `feed` opens a feed object
and `item url, title, description, date, author, source, enclosure` adds one
item to it.

A plugin test reaches no network and needs no credential. A plugin that cannot
be tested without one is tested for what it can be — its settings handling, its
message construction — and the rest is left to the integration Recipes under
`test/integration`, which are run by hand.

### 3.10 Where a plugin goes

| Category | It should | It should not |
| --- | --- | --- |
| `Subscription` | Acquire from outside and produce a pipeline | Publish |
| `CustomFeed` | Build a feed from a source that is not one | Filter |
| `Filter` | Select, reorder, rewrite; return a pipeline | Have side effects outside the pipeline |
| `Store` | Persist, and drop what has been seen before | Send anything outward |
| `Provide` | Emit `content_encoded` elsewhere | Alter the pipeline |
| `Notify` | Send a notification, return the pipeline unchanged | Alter the pipeline |
| `Publish` | Send the result out, print it, or write it as a document; return the pipeline | Alter the pipeline |

Nothing enforces this. It is what makes a Recipe readable, and it is what a
reviewer will ask about.

---

## 4. Writing a plugin, end to end

```sh
automatic scaffold                       # creates ~/.automatic and its categories
$EDITOR ~/.automatic/plugins/filter/short_title.rb
```

```ruby
# -*- coding: utf-8 -*-
# Name::      Automatic::Plugin::Filter::ShortTitle
# Description:: Keep only items whose title is at most `max` characters.

module Automatic::Plugin
  class FilterShortTitle
    DEFAULT_MAX_LENGTH = 40

    def initialize(config, pipeline = [])
      @config   = config || {}
      @pipeline = pipeline
      @max      = (@config['max_length'] || DEFAULT_MAX_LENGTH).to_i
    end

    def run
      @pipeline.each_with_object([]) do |feeds, returned|
        next if feeds.nil?

        kept = feeds.items.select { |item| item.title.to_s.length <= @max }
        Automatic::Log.puts('info', "ShortTitle: kept #{kept.size} of #{feeds.items.size}")
        returned << Automatic::FeedMaker.create_pipeline(kept) unless kept.empty?
      end
    end
  end
end
```

```yaml
plugins:
  - module: SubscriptionFeed
    config:
      feeds:
        - https://example.com/feed
  - module: FilterShortTitle
    config:
      max_length: 30
  - module: PublishConsole
```

```sh
automatic -c ~/.automatic/config/short.yml
```

Nothing was registered and no framework file was touched. Naming the class
`FilterShortTitle` and putting it in `filter/short_title.rb` is the whole of the
wiring.

---

## 5. Reading the catalogue

Section 6 lists every plugin shipped in the gem. Each carries a status:

| Status | Meaning |
| --- | --- |
| **Supported** | Works on the supported Ruby versions with the current dependencies. Covered by the default test suite where it can be. |
| **Supported (external)** | The plugin is current, but it needs something the operator provides — a running service, an installed command, a credential, a data file. |
| **Needs rework** | The service and the capability still exist, but this plugin speaks an interface that has been replaced. It will not work as written, and restoring it is a self-contained piece of work. |

There is no fourth row. There used to be one, holding plugins whose service had
shut down, and the plugins that were in it have been removed rather than kept:
see section 8.

Two rules govern this table, and they are the reason it exists at all:

- **Nothing is faked.** A plugin is not stubbed, mocked or simulated to make a
  test pass or a catalogue entry look better. Where a plugin's gem is absent
  its specs are excluded from the default suite, and that absence is the honest
  signal. A service that no longer answers is not given a fake endpoint to
  answer with; the plugin goes.
- **Nothing is kept for being old.** A plugin ships because it has a current
  practical use, not because it once did. Git history is where the previous
  implementations are, and it keeps them without their being installed on
  anyone's machine.

**Supported is not the same as covered by the required workflow.** A Supported
plugin whose gem is an optional plugin dependency — the store plugins, the ones
that read HTML, `FilterSanitize`, `FilterDescriptionLink` — works, and is
simply not part of what a green required build guarantees, because the default
bundle does not install that gem. Its entry says so, and installing the gem runs
its spec as part of the ordinary suite, which is also what the separate
`plugins` workflow does. Nothing here is classified by what CI happens to run; a
plugin is not demoted for needing a gem, and is not promoted by a test that CI
never executes.

**This classification is a snapshot taken in August 2026,** based on the
published status of each service and on what each plugin's code actually calls.
The statuses that depend on an outside service can change without any commit
here. Where a status was reached from published information rather than from a
live check, the entry says so. To verify one yourself, run its Recipe from
`test/integration` by hand; those are not part of CI and never will be.

Restoring the one **Needs rework** plugin is a self-contained piece of work and
a good first contribution.

---

## 6. The plugins

### 6.1 Subscription

Acquire from outside; produce a pipeline. Called first in a Recipe.

#### SubscriptionFeed — **Supported**

`subscription/feed.rb`. Fetches and parses feeds. The plugin most Recipes start
with.

```yaml
  - module: SubscriptionFeed
    config:
      feeds:
        - https://example.com/feed
        - https://example.org/rss
      retry: 3
      interval: 5
```

| Key | Type | Meaning |
| --- | --- | --- |
| `feeds` | sequence | Feed URLs, fetched in order. Required. |
| `retry` | integer | Attempts after the first, per feed. Default `0`. |
| `interval` | integer | Seconds between attempts. Default `0`. |

A feed that fails after its retries is logged and skipped; the others still run.

`interval` is now waited. The line that was meant to wait it assigned to a
local variable named `sleep` and returned at once, in this plugin and in every
other that had a retry loop, so a Recipe asking to be gentle with a host was
not being gentle. A Recipe that set `interval` will take longer than it used
to and will behave as it always said it did.

#### SubscriptionLink — **Supported**

`subscription/link.rb`. Fetches pages and makes an item of every `<a href>`.
For sites that publish no feed. Returns only what it fetched, discarding any
incoming pipeline.

| Key | Type | Meaning |
| --- | --- | --- |
| `urls` | sequence | Page URLs. Required. |
| `retry` | integer | Attempts after the first. Default `0`. |
| `interval` | integer | Seconds between requests. Default `0`. |

Set `interval` when fetching several pages from one host.

Reads HTML through `FeedParser.parse_html`, so it needs `nokogiri`:
`gem install nokogiri`, or the `html` group in a checkout.

#### SubscriptionXml — **Supported**

`subscription/xml.rb`. `GET`s an XML endpoint, converts the document to a hash,
and puts it in one item's `content_encoded`. Pair with `ProvideFluentd` to move
an XML API into a log pipeline. Needs `activesupport`.

| Key | Type | Meaning |
| --- | --- | --- |
| `urls` | sequence | XML endpoints. Required. |
| `retry` | integer | Attempts after the first. Default `0`. |
| `interval` | integer | Seconds between requests. Default `0`. |

#### SubscriptionText — **Supported**

`subscription/text.rb`. Builds a feed from literal values or TSV files. Reaches
no network, which makes it the plugin to test a Recipe's later half with.

| Key | Type | Meaning |
| --- | --- | --- |
| `titles` | sequence | One item per title, no link |
| `urls` | sequence | One item per URL, no title |
| `feeds` | sequence | Mappings of `title`, `url`, `description`, `author`, `comments` |
| `files` | sequence | TSV paths; columns are title, url, description, author, comments |

The TSV separator is a tab, the file is read as UTF-8, and `~` is expanded. Any
combination of the four keys may be given.

#### SubscriptionTumblr — **Supported (external)**

`subscription/tumblr.rb`. Fetches a Tumblr blog's pages, takes the links, and
drops any that leave the blog's own host. `pages` walks `/page/2` and onward.

| Key | Type | Meaning |
| --- | --- | --- |
| `urls` | sequence | Blog URLs. Required. |
| `pages` | integer | How many pages back to walk. Default `1`. |
| `retry` | integer | Attempts after the first. Default `0`. |
| `interval` | integer | Seconds between requests. Default `0`. |

It reads HTML written for a browser, so it needs `nokogiri` — `gem install
nokogiri`, or the `html` group in a checkout — and it depends on the theme a
given blog uses and on Tumblr's page structure. Verify against the blog you mean
to follow before putting it in `cron`, and set `interval`.

### 6.2 CustomFeed

#### CustomFeedWeb — **Supported**

`custom_feed/web.rb`. Fetches HTML index pages and builds one feed per page
from the article links it lists. For a site that publishes no feed and whose
list page has more structure than `SubscriptionLink` reads: CSS selectors say
where an article is and what belongs to it, and the links are resolved,
filtered and deduplicated on the way into the feed.

```yaml
  - module: CustomFeedWeb
    config:
      retry: 2
      interval: 1
      sites:
        - url: https://example.com/news/
          name: Example News
          item_selector: article
          link_selector: h2 a
          title_selector: h2
          description_selector: .summary
          date_selector: time
          same_host: true
          include:
            - ^https://example\.com/news/
          exclude:
            - /category/
          fetch_items: 50
```

| Key | Type | Meaning |
| --- | --- | --- |
| `sites` | sequence | Page mappings, fetched in order. Required. |
| `retry` | integer | Attempts after the first, per page. Default `0`. |
| `interval` | integer | Seconds between requests. Default `0`. |

Each element of `sites` is a mapping. A bare `- https://example.com/news/` is
not accepted: a page's settings are what this plugin is for, and one shorthand
kept working forever is a second format to support.

| Key | Type | Meaning |
| --- | --- | --- |
| `url` | string | The page to fetch. Required. |
| `name` | string | Channel title. Default the page's `<title>`, then its host. |
| `item_selector` | string | The node one article occupies. |
| `link_selector` | string | The permalink, evaluated inside the article where there is one. Default `a[href]`. |
| `title_selector` | string | The title, inside the article. Default the link's own text. |
| `description_selector` | string | The summary the page prints, taken as text. |
| `date_selector` | string | The publication date, inside the article. |
| `same_host` | boolean | Drop a URL whose host is not the page's. Default `true`. |
| `include` | sequence | Regular expressions; a URL matching none of them is dropped. |
| `exclude` | sequence | Regular expressions; a URL matching one of them is dropped. |
| `fetch_items` | integer | Items per page, from the top. Default `100`; `0`, a negative value and an absent one all mean the default. |

There are three ways a page is read, and which one applies follows from the
selectors given:

- **Neither `item_selector` nor `link_selector`.** Every `a[href]` on the page
  is a candidate and its text is the title. This is the mode to start with.
- **`link_selector` only.** Each node it selects is a candidate, and its text
  is the title. `main h2 a` is the usual shape of it.
- **`item_selector`.** Each node it selects is one article, and
  `link_selector`, `title_selector`, `description_selector` and
  `date_selector` are evaluated inside that node. Without `link_selector` the
  article's first `a[href]` is the permalink; without `title_selector` the
  link's own text is the title.

`title_selector`, `description_selector` and `date_selector` are read inside an
article, so giving one without `item_selector` names no article to read it in
and is refused as a settings error.

A candidate URL is resolved against the page it was found on — `/articles/42`,
`../42` and `//example.com/42` all become the URL a reader would follow — and
then judged in this order: HTTP or HTTPS, not the page itself, `same_host`,
`include`, `exclude`, already seen, and finally `fetch_items`. The fragment is
removed, because two links differing only in their anchor are one article. The
query string is kept, because `?id=42` is frequently the whole of what
identifies one; no canonical form is guessed. `same_host` is an exact host
match, so `blog.example.com` is not `www.example.com`.

The page's own order is kept. A list page's order is the only ordering
information it carries, and nothing here sorts by date; `FilterSort` is where
a Recipe asks for that.

`date_selector` prefers the `datetime` attribute of a `<time>` element and
otherwise parses the node's text. A date that cannot be read is logged and the
item keeps its place without one — the time the page was fetched is not the
time the article was published, and is never substituted for it.

The plugin keeps no state: it fetches the page, and what the page lists now is
what it returns. Whether an item has been published before is the record
`StorePermalink` keeps, which is what the usual Recipe puts after it:

```yaml
plugins:
  - module: CustomFeedWeb
    config:
      sites:
        - url: https://example.com/news/
          link_selector: main h2 a

  - module: StorePermalink
    config:
      db: web-watch.db

  - module: PublishMarkdown
    config:
      file: ~/.automatic/markdown/web-watch.md
      mode: append
```

A page that could not be fetched is retried, then logged and skipped, and the
other pages still produce their feeds. Settings that cannot be carried out —
a site that is not a mapping, a missing or unfetchable `url`, an `include` or
`exclude` that is not a regular expression, a selector combination that names
no article — are refused before anything is fetched, because a second attempt
would fail identically.

Nothing else is fetched: no article body, no next page, no sitemap, no feed
autodiscovery, and no link found on the page is followed. One run makes one
request per site. Set `interval` when several sites are on one host.

Needs `nokogiri`, which it reads the page with: `gem install nokogiri`, or the
`html` group in a checkout.

#### CustomFeedSVNLog — **Supported (external)**

`custom_feed/svn_log.rb`. Runs `svn log --xml` against a repository and makes a
feed of the revisions. Needs the `svn` command, which is the operator's to
install, and **no gem of its own**: it reads the document with REXML, which is
a runtime dependency of the framework already. It used to need `xml-simple`,
whose last release was in 2021.

| Key | Type | Meaning |
| --- | --- | --- |
| `target` | string | Repository URL. Required. |
| `fetch_items` | integer | Revisions to fetch. Default `30`. |
| `title` | string | Channel title. Default empty. |

The command is run as an argument vector rather than through a shell, so a
repository URL cannot become part of a command line. Point `target` at a
repository you control regardless: `svn` itself will do what the URL tells it
to.

A repository with no revisions in the window asked for returns the pipeline
unchanged, with a warning. RSS 1.0 has no representation for a channel with no
items, and this used to end the run with a parser error.

### 6.3 Filter

Select, reorder or rewrite. No side effects outside the pipeline.

#### FilterIgnore — **Supported**

`filter/ignore.rb`. Drops items containing any listed keyword. Matching is a
substring test, so an empty string drops everything.

| Key | Type | Meaning |
| --- | --- | --- |
| `title` | sequence | Drop when the title contains any of these |
| `link` | sequence | Drop when the link contains any of these |
| `description` | sequence | Drop when the description contains any of these |

All three are optional and combine as "or". An item whose field is missing is
kept, with a warning.

#### FilterAccept — **Supported**

`filter/accept.rb`. The complement of `FilterIgnore`: keeps only items that
match. Same three keys, same substring rule. An item whose field is missing is
not matched, and says so; it used to end the run with a `NoMethodError`, which
is not what its complement does with the same item.

#### FilterSort — **Supported**

`filter/sort.rb`. Sorts each feed's items by date.

| Key | Type | Meaning |
| --- | --- | --- |
| `sort` | string | `asc` sorts oldest first. Anything else, including absent, sorts newest first. |

Items must carry a date; a feed built from a source without one will fail here.

`sort` collides with a `Hashie::Mash` built-in and logs a warning per run. The
setting works; see section 2.6.1.

#### FilterOne — **Supported**

`filter/one.rb`. Reduces each feed to a single item.

| Key | Type | Meaning |
| --- | --- | --- |
| `pick` | string | `last` takes the last item. Anything else, including absent, takes the first. |

#### FilterRand — **Supported**

`filter/rand.rb`. Shuffles each feed's items. Combined with `FilterOne`, picks
one at random. No settings.

#### FilterClear — **Supported**

`filter/clear.rb`. Returns an empty pipeline. Used to end a Recipe after a store
plugin has done the work, so that later plugins publish nothing. No settings.

#### FilterImage — **Supported**

`filter/image.rb`. Sets `link` to `nil` unless it names an image. Note that it
does not remove the items — it blanks their links, and the plugins after it
skip items whose link is `nil`. No settings.

The extensions are `.jpg`, `.jpeg`, `.gif`, `.png`, `.tif`, `.tiff`, `.webp`
and `.avif`, and the test is on the URL's **path**. Both of those changed:
`.webp` and `.avif` are what an image link on the current web frequently is,
and testing the whole URL meant that `photo.jpg?w=1280` — which is how most of
what serves images now serves them — was not recognised as one. A Recipe using
this filter will therefore keep links it used to blank.

#### FilterImageSource — **Supported**

`filter/image_source.rb`. Replaces each item with one item per image found: the
images in the description, or, if there are none, the images on the page the
link points at. Fetching pages means network access. No settings.

Needs `nokogiri`: `gem install nokogiri`, or the `html` group in a checkout.

The description is read with that parser rather than scanned for the literal
text `<img src="`, so a document quoting its attributes with apostrophes or
writing `src` after another attribute is no longer invisible to it, and a
relative `src` is resolved against the item's own link. A page that cannot be
read is a warning and no images, rather than the end of the run.

#### FilterAbsoluteURI — **Supported**

`filter/absolute_uri.rb`. Rewrites relative links to absolute ones.

| Key | Type | Meaning |
| --- | --- | --- |
| `url` | string | The base. A trailing slash is added if absent. Required. |

A link that already carries a scheme is left alone. That test matched `http://`
only, so an `https://` link was treated as relative and had the base prepended
to it; a Recipe that combined this filter with an HTTPS source was producing
links that went nowhere.

#### FilterSanitize — **Supported**

`filter/sanitize.rb`. Strips HTML from descriptions, using the `sanitize` gem.

| Key | Type | Meaning |
| --- | --- | --- |
| `mode` | string | `basic`, `relaxed`, or `restricted`. Default `restricted`. |

Needs the `sanitize` gem, which is an optional plugin dependency and is not
installed with the framework. Its spec is therefore outside the default suite
and outside CI; installing the gem brings the spec back into the ordinary run.
See [`DEPLOYMENT.md`](DEPLOYMENT.md).

#### FilterTumblrResize — **Supported**

`filter/tumblr_resize.rb`. Rewrites a Tumblr image link to the largest variant.
Assumes `FilterImage` or `FilterImageSource` has already put an image URL in
the link. No settings.

Tumblr has served images under two URL schemes, and both are rewritten. The
older one carries the size as a suffix on the file name — `tumblr_xxx_500.jpg`
becomes `tumblr_xxx_1280.jpg` — and is what images uploaded before 2019 still
use. The newer one carries it as a path segment — `/s540x810/` becomes
`/s1280x1920/` — and is what everything since uses. Only the first was handled,
which is why this filter appeared to do nothing on a blog whose posts are
recent.

#### FilterDescriptionLink — **Supported**

`filter/description_link.rb`. Takes the last HTTP or HTTPS URL out of the
description and makes it the link. For feeds that carry the real destination in
the body.

| Key | Type | Meaning |
| --- | --- | --- |
| `clear_description` | `1` | Empty the description afterwards. Any other value leaves it. |
| `get_title` | `1` | Fetch the new link and use its `<title>`. Any other value skips it. |

`get_title` makes one request per item; use `FilterOne` or a store plugin before
it on a large feed.

**Both settings were being ignored in every real run.** The test that guarded
them asked whether the settings mapping was a `Hash`, and the framework hands a
plugin a `Hashie::Mash`, which is a subclass and so is not that class. A Recipe
setting `clear_description` or `get_title` will now do what it asked for.

Needs `nokogiri`, which it reads the fetched page with — `gem install
nokogiri`, or the `html` group in a checkout. It no longer needs `nkf`: the
parser detects a page's encoding itself, which is one optional dependency
fewer, and `nkf` had left the standard library after Ruby 3.3. This plugin's
spec is outside the default suite and outside the required workflow because
`nokogiri` is an optional dependency. See [`DEPLOYMENT.md`](DEPLOYMENT.md).

#### FilterFullFeed — **Supported (external)**

`filter/full_feed.rb`. Replaces a summary with the article body, by matching the
link against a "siteinfo" database of URL patterns and XPaths and fetching the
page.

| Key | Type | Meaning |
| --- | --- | --- |
| `siteinfo` | string | File name under the assets directory. Required. |

Needs `nokogiri`: `gem install nokogiri`, or the `html` group in a checkout.

The shipped `assets/siteinfo/items_all.json` is a snapshot of the LDRFullFeed
database taken from `wedata.net`, which no longer operates, so the file cannot
be refreshed from its origin and its newest entries are from 2013. The plugin
works; how well it works depends on whether the sites you read are in that
snapshot and still laid out the same way. Supplying your own file in
`~/.automatic/assets/siteinfo/` is the way to keep it useful.

Three things follow from the database being that old, and the plugin now
accounts for each:

- **A link matches under either scheme.** 3,448 of the 3,504 usable records
  anchor on a scheme and all but twenty of those say `^http://`. The sites they
  name have since moved to HTTPS, which is what a feed hands over, so matching
  the link as it stands matched almost nothing and the filter quietly did
  nothing at all. A record describes a site's layout, not how it is
  transported, so the link is tried under both. Only the match is rewritten;
  the page is fetched from the link the feed gave.
- **A record that selects nothing leaves the summary alone.** A site redesigned
  since its XPath was written selects no nodes, and putting that empty result
  into the item replaced a perfectly good summary with an empty description.
  The item keeps what it arrived with, and the miss is logged at `warn` with
  the XPath that missed.
- **The page's own encoding is believed before the record's.** The page is
  parsed from the stream, so a charset in a `meta` tag is read even when the
  response declared none. A record's `enc` is the fallback for a page that
  declares nothing anywhere — 1,186 records carry one, mostly EUC-JP and
  Shift_JIS — and an `enc` naming an encoding Ruby does not have is ignored
  rather than raised. What comes out is UTF-8 either way.

A record with no URL pattern, no XPath, or a pattern that is not a regular
expression is dropped when the file is loaded rather than being allowed to fail
a match later; an empty pattern would otherwise match every link in the feed.
The remaining patterns are compiled once, not once per item.

#### FilterGithubFeed — **Supported**

`filter/github_feed.rb`. Converts Atom entries — where `title`, `id` and
`content` are elements with a `.content` — into the flat items the rest of the
pipeline expects. Needed because GitHub publishes Atom, not RSS. No settings.

A field that is already a string is taken as it stands, so a pipeline that has
been through another filter first is no longer a `NoMethodError`.

#### FilterJoin — **Supported**

`filter/join.rb`. Joins every item in the pipeline into one item. Many items
in, one item out, and that is the whole of it: it fetches nothing, summarizes
nothing, and knows nothing about what reads the result.

| Key | Type | Meaning |
| --- | --- | --- |
| `title` | string | The title of the joined item. Default `Joined items`. |

**In**: the pipeline as it stands — any number of feeds, any number of items; a
feed that is `nil` is passed over. **Out**: one feed holding one item. The whole
pipeline becomes one item rather than one item per feed, because the point of
joining is to have a single text; a Recipe that wants one item per feed still
has its feeds separate before this plugin runs.

The description is plain text, with a numbered heading per item so that
whatever reads it can tell one article from the next:

```text
ARTICLE 1
Title: Ruby 4.1 released
URL: https://example.com/a

The body of the first article.

ARTICLE 2
Title: PostgreSQL 19 released
URL: https://example.com/b

The body of the second article.
```

A title, link or description an item does not carry is written as empty, so
every section has the same shape. **An input with no items produces an empty
pipeline**, not an item that says nothing.

**The joined item has no link.** It is several articles at once, so there is no
page it points at, and putting the first article's URL there would name a
source for text that is not only from it. That has one consequence for a
Recipe: the store plugins are keyed on the link and drop an item without one,
so `StorePermalink`, `StoreFullText` and `StoreDigest` belong **before** this
plugin, where there is still one item per article to record. `PublishMarkdown`
heads the joined item with its title and writes no `Link` bullet.

Nothing here is about AI. Joining a day's log lines, notifications or release
notes into one document is the same operation, and this plugin adds no prompt
of its own — what the joined text is for is decided by whatever the Recipe puts
next.

```yaml
  - module: FilterJoin
    config:
      title: Daily Digest
```

**The four AI filters.** The plugins that follow each send an item's
description to one AI service and put the answer back in its place. They are
four plugins rather than one with a `provider` setting, and that is the design
rather than an accident: the services differ in endpoint, authentication,
request body, answer shape, error format and available models; each of those
moves without asking the others; and a Recipe naming `FilterClaude` says on its
face where the text is being sent.
Changing service is changing that one line.

**None of them is a summarizer.** The Recipe's `prompt` is the instruction and
the item's description is the text it applies to, so summarizing, translating,
extracting, reformatting and classifying are the same plugin with a different
prompt. There is no default prompt: a Recipe without one is refused with an
`ArgumentError` rather than being given a purpose it did not ask for. The two
are sent as separate fields — a system instruction and a user turn — so that
what an article says is text to be worked on, never an instruction to obey.

What the four have in common:

| Point | What it is |
| --- | --- |
| Required settings | `token`, `model` and `prompt`. A Recipe missing one is an `ArgumentError` before the first request. |
| `retry`, `interval` | Attempts after a failure, and seconds to wait between them. Both default to `0`. |
| What is retried | The network, a `429`, a `5xx`. |
| What is not | A refused request, an answer that is not JSON, an answer whose shape is not the one the service documents, and a setting that is missing or wrong. These raise and end the run, because the next attempt would fail the same way. |
| Input and output | The pipeline's feeds and items, in the same number and the same order. Only `description` is replaced; `title`, `link`, `date` and the rest are untouched. |
| An item with no description | Logged and passed over. Nothing is sent, and nothing is emptied. |
| A failure | Never leaves an empty description behind. A run that could not transform an item ends rather than publishing the article as a blank. |
| The credential | A Recipe setting, which makes the Recipe a secret file. It is never logged, never in an exception message, and never written into an item. TLS certificates are verified. |

Each of them makes **one request per item**, which is what makes the order of a
Recipe worth thinking about:

- `FilterJoin` → an AI filter: the articles become one text and the service is
  asked about it **once**. This is the digest arrangement — one answer over
  everything, which is not the same as a list of separate summaries.
- An AI filter → `FilterJoin`: each article is transformed **on its own**, and
  the answers are joined afterwards. Use `FilterOne` or a store plugin ahead of
  it on a large feed; each item is a billed request.

#### FilterOpenAI — **Supported (external)**

`filter/open_ai.rb`. Sends each item's description to the OpenAI API and
replaces it with the answer. It speaks the Responses API,
`https://api.openai.com/v1/responses`, which is the interface OpenAI recommends
for new integrations, and authenticates with the token as a bearer token.

| Key | Type | Meaning |
| --- | --- | --- |
| `token` | string | OpenAI API key. Required. |
| `model` | string | Model name, as OpenAI names it. Required. |
| `prompt` | string | The instruction, sent as the request's `instructions`. Required. |
| `retry` | integer | Attempts after a failure. Default `0`. |
| `interval` | integer | Seconds between attempts. Default `0`. |

The endpoint is not a setting: there is one, an operator has no version of this
plugin that talks to a different host, and a setting for it would be a way to
send the token somewhere else. The answer is read out of the typed `output`
array, from the `output_text` of the assistant's message.

```yaml
  - module: FilterOpenAI
    config:
      token: sk-...
      model: gpt-5.6
      prompt: |
        Summarize the following articles as one digest, in Japanese.
      retry: 2
      interval: 2
```

#### FilterClaude — **Supported (external)**

`filter/claude.rb`. Sends each item's description to the Anthropic Messages
API, `https://api.anthropic.com/v1/messages`, and replaces it with the answer.
Anthropic authenticates with an `x-api-key` header rather than a bearer token,
requires an API version header, and requires a `max_tokens` — so this plugin
sends all three, and has one setting the others do not.

| Key | Type | Meaning |
| --- | --- | --- |
| `token` | string | Anthropic API key, sent as `x-api-key`. Required. |
| `model` | string | Model name, as Anthropic names it. Required. |
| `prompt` | string | The instruction, sent as the request's `system`. Required. |
| `max_tokens` | integer | The longest answer to allow, which this API requires. Default `4096`. |
| `retry` | integer | Attempts after a failure. Default `0`. |
| `interval` | integer | Seconds between attempts. Default `0`. |

The `anthropic-version` header is a constant, not a setting: it is the version
of the HTTP interface rather than of a model, and changing it is a change to
this plugin. The answer is the `text` of the content blocks the API returns;
blocks of other kinds are passed over.

```yaml
  - module: FilterClaude
    config:
      token: sk-ant-...
      model: claude-opus-5
      prompt: |
        Summarize the following articles as one digest, in Japanese.
      max_tokens: 2048
      retry: 2
      interval: 2
```

#### FilterGemini — **Supported (external)**

`filter/gemini.rb`. Sends each item's description to the Google Gemini API and
replaces it with the answer. Gemini names the model in the URL rather than in
the body, so the endpoint is
`https://generativelanguage.googleapis.com/v1beta/models/<model>:generateContent`,
built from the Recipe's `model`. The API key goes in an `x-goog-api-key`
header, which is how Google documents it and what keeps a credential out of a
URL and out of anything that logs one.

| Key | Type | Meaning |
| --- | --- | --- |
| `token` | string | Gemini API key, sent as `x-goog-api-key`. Required. |
| `model` | string | Model name, bare — `gemini-3.5-flash`, not `models/gemini-3.5-flash`. Required. |
| `prompt` | string | The instruction, sent as `system_instruction`. Required. |
| `retry` | integer | Attempts after a failure. Default `0`. |
| `interval` | integer | Seconds between attempts. Default `0`. |

The request is built of `contents` and `parts` as this API defines them, and is
not bent into another service's shape. The answer is the text of the first
candidate's parts; an answer carrying no candidate — which is what a request
stopped by a safety filter looks like — is an error rather than an empty
description.

```yaml
  - module: FilterGemini
    config:
      token: AIza...
      model: gemini-3.5-flash
      prompt: |
        Summarize the following articles as one digest, in Japanese.
      retry: 2
      interval: 2
```

#### FilterSakuraAI — **Supported (external)**

`filter/sakura_ai.rb`. Sends each item's description to the Sakura AI Engine,
`https://api.ai.sakura.ad.jp/v1/chat/completions`, and replaces it with the
answer. The token is a bearer token, and the request is the chat completions
form: the prompt as a `system` message, the description as a `user` message.

| Key | Type | Meaning |
| --- | --- | --- |
| `token` | string | Sakura AI Engine token. Required. |
| `model` | string | Model name, as the service's control panel lists it. Required. |
| `prompt` | string | The instruction, sent as the `system` message. Required. |
| `retry` | integer | Attempts after a failure. Default `0`. |
| `interval` | integer | Seconds between attempts. Default `0`. |

**This interface is OpenAI-compatible, and this is still its own plugin.** It is
a different service: a different endpoint, a different account, a different set
of models, its own limits and its own errors, any of which may move without
OpenAI moving. Folding it into `FilterOpenAI` behind a setting would trade a
Recipe that says where the text goes for a Recipe that does not.

```yaml
  - module: FilterSakuraAI
    config:
      token: ...
      model: gpt-oss-120b
      prompt: |
        以下の記事群について、個別記事の要約を羅列するのではなく、
        全体を一つのダイジェストとして日本語で要約してください。
      retry: 2
      interval: 2
```

A digest, end to end: find the articles, drop the ones already seen, fetch
their bodies, strip the markup, join them, ask once, write the answer out.

```yaml
plugins:
  - module: CustomFeedWeb
    config:
      sites:
        - url: https://example.com/news/

  - module: StorePermalink
    config:
      db: digest.db

  - module: FilterFullFeed
    config:
      siteinfo: items_all.json

  - module: FilterSanitize

  - module: FilterJoin
    config:
      title: Daily Digest

  - module: FilterSakuraAI
    config:
      token: ...
      model: gpt-oss-120b
      prompt: |
        以下の記事群について、個別記事の要約を羅列するのではなく、
        全体を一つのダイジェストとして日本語で要約してください。
      retry: 2
      interval: 2

  - module: PublishMarkdown
    config:
      file: ~/.automatic/markdown/digest.md
      mode: append
```

Changing service is changing the one entry: `FilterSakuraAI` for
`FilterOpenAI`, `FilterClaude` or `FilterGemini`, with that plugin's own
settings. Nothing before or after it changes.

### 6.4 Store

Persist, and drop what has already been seen. A store plugin is what makes a
Recipe safe to run repeatedly.

`StorePermalink`, `StoreFullText` and `StoreDigest` keep their records in SQLite
through ActiveRecord. Both gems are these plugins' own optional dependencies
rather than the framework's: `gem install activerecord sqlite3`, or the `store`
group in a checkout. A Recipe that stores nothing needs neither.
See [`DEPLOYMENT.md`](DEPLOYMENT.md).

They answer different questions, and a Recipe may ask more than one of them:
`StorePermalink` whether this **link** has been seen, `StoreFullText` whether
this link or title has been stored with its body, `StoreDigest` whether this
**content** has been seen, whatever it was published under.

#### StorePermalink — **Supported**

`store/permalink.rb`. Records each item's link in SQLite and passes on only the
links not already recorded. The usual guard against publishing the same item
twice.

| Key | Type | Meaning |
| --- | --- | --- |
| `db` | string | Database file name, under `~/.automatic/db`. Required. |

The file is created on first use, as is the table. Deleting it makes everything
look new again.

#### StoreFullText — **Supported**

`store/full_text.rb`. Records title, link, description and `content_encoded`,
and passes on only what is new. Deduplicates on link **or** title, so a
republished article with a new URL is not stored twice. Pair with
`FilterFullFeed` to archive article bodies.

| Key | Type | Meaning |
| --- | --- | --- |
| `db` | string | Database file name, under `~/.automatic/db`. Required. |

#### StoreDigest — **Supported**

`store/digest.rb`. Takes the SHA-256 digest of the item fields the Recipe names,
records it in SQLite, and passes on only the items whose digest was not recorded
already. Content identity, where `StorePermalink` is URL identity: a page that
reissues one article under a new URL is one item here, and one URL whose content
changed is a new item — the opposite of what `StorePermalink` decides in both
cases. Pair it with `CustomFeedWeb`, whose items are whatever an index page
currently lists.

| Key | Type | Meaning |
| --- | --- | --- |
| `db` | string | Database file name, under `~/.automatic/db`. Required. |
| `fields` | list | The fields the digest is taken over, in the order written. Default: `title`, `description`. |

```yaml
plugins:
  - module: CustomFeedWeb
    config:
      sites:
        - url: https://example.com/news/

  - module: StoreDigest
    config:
      db: web-digest.db

  - module: PublishMarkdown
    config:
      file: ~/.automatic/markdown/web-watch.md
      mode: append
```

The first run passes on everything the page listed and records a digest for
each. The second passes on nothing, because the page still lists the same
articles. A run in which one article has been added passes on that one.

**`fields`** names any of `title`, `link`, `description`, `author`, `comments`,
`source` and `content_encoded`. `date` is not among them — an item republished
unchanged carries a new date often enough to defeat the purpose — and neither is
`enclosure`, which is a structure rather than a value.

- The order is part of the fingerprint. `[title, description]` and
  `[description, title]` are two different specifications and produce different
  digests; nothing is sorted behind the Recipe's back.
- **The fields named are the fields used.** A Recipe that asks for
  `content_encoded` gets `content_encoded`, and an item whose body is empty is
  not quietly judged on its title instead. What the Recipe says two identical
  items are is what this plugin obeys.
- Anything but an absent `fields` is taken as written: an empty list, a name
  that is not a field, a name given twice and a value that is not a list are
  each refused with an `ArgumentError` before the database is opened, rather
  than corrected into something the Recipe did not ask for.
- `db` is required, and an empty name is refused the same way.

**What "the same content" means here.** Each value is read as UTF-8, with
invalid and undefined characters replaced, normalized to Unicode NFC, its runs
of whitespace collapsed to one space and its ends trimmed. The values are joined
with their field names into one canonical string — `title`, NUL, the title, NUL,
`description`, NUL, the description — and that string is hashed with SHA-256.
The algorithm is fixed; there is no setting for it and no column recording it.

Two items are therefore the same item when their selected fields are **exactly**
equal after that normalization, and not otherwise. A difference of case, of
punctuation or of markup is a difference of content. This is not similarity
matching: there is no fuzzy comparison, no edit distance, no embedding and no
semantic judgement anywhere in it, and two articles that report one event in
different words are two items.

**An item with nothing to hash is passed on, not stored.** Where every field the
Recipe named is empty after normalization — `fields: [description]` on an item
that has no description — there is nothing to identify the item by. Hashing the
empty string would make every such item the same item and silence all but the
first of them for good, so instead the plugin logs a warning naming the item's
link and passes it on unjudged. An item is never lost for having too little
content. A field that is empty while another is not takes part in the digest as
an empty value, so an item with a title and no description differs from the same
item with both.

**A database failure ends the run.** A failed read or a failed write is not
rescued here, which is deliberate and is a difference from `StoreFullText`: an
item passed on after its digest failed to store would be published again on the
next run, and de-duplication that quietly stops de-duplicating is worse than a
run that stops. The digest column carries a unique index, so two runs of one
Recipe overlapping cannot both store one digest; the second write is rejected
and its item is treated as seen.

The digest is all that is stored — no title, no body, no URL. Recording what an
item said is `StoreFullText`'s work, and pairing the two is how a Recipe gets
both.

`StorePermalink` and `StoreDigest` may stand in one Recipe, each with its own
database, and the pair is worth having: the first drops what has been seen at
that URL, the second drops what has been seen under any URL.

```yaml
plugins:
  - module: CustomFeedWeb
    config:
      sites:
        - url: https://example.com/news/

  - module: FilterFullFeed

  - module: StoreDigest
    config:
      db: fulltext-digest.db
      fields:
        - content_encoded

  - module: PublishMarkdown
    config:
      file: ~/.automatic/markdown/web-watch.md
      mode: append
```

With the body fetched first, the digest is taken over the article itself, so a
headline edited between runs no longer republishes the article.

#### StoreFile — **Supported**

`store/file.rb`. Downloads what each link points at and rewrites the link to a
`file://` URI, which is how `PublishAmazonS3` later knows it has a local file.

| Key | Type | Meaning |
| --- | --- | --- |
| `path` | string | Directory to save into; created if absent. Required. |
| `retry` | integer | Attempts after the first. Default `0`. |
| `interval` | integer | Seconds between downloads. Default `0`. |
| `access_key` | string | S3 only. Omit to use the SDK's own credential chain. |
| `secret_key` | string | S3 only. |
| `bucket_name` | string | S3 only. The link's own host is used where this is absent. |
| `region` | string | S3 only. Omit to use the SDK's own resolution. |

Only HTTP and HTTPS links are downloaded: a link comes from a feed, and a store
plugin that would read `file://` on being asked to is a store plugin that can
be asked to read anything.

A link whose scheme is `s3://` or `s3n://` is fetched from a bucket instead,
through **AWS SDK for Ruby version 3** — `aws-sdk-s3`, the SDK AWS publishes
today. This was written against version 1's `AWS::S3`, which no published gem
provides any more. `s3n://` is what Recipes written for this plugin use and is
still accepted; `s3://` is the spelling everything else uses and is accepted as
well. The gem is required inside that branch, so the ordinary download path
works without it installed: `gem install aws-sdk-s3`, or the `s3` group in a
checkout.

Set `interval` when downloading a series from one host.

### 6.5 Provide

#### ProvideFluentd — **Supported (external)**

`provide/fluentd.rb`. Posts each item's `content_encoded` to Fluentd. Distinct
from `PublishFluentd`, which posts the item's fields. Pair with
`SubscriptionXml` to move an XML API into Fluentd. Needs the `fluent-logger`
gem and a Fluentd instance.

| Key | Type | Meaning |
| --- | --- | --- |
| `host` | string | Fluentd host |
| `port` | integer | Fluentd port |
| `tag` | string | Tag, for example `automatic.feed` |
| `mode` | string | `test` builds no connection and sends nothing |

`content_encoded` must be something Fluentd accepts as a record; a plain string
is logged as an error and skipped.

### 6.6 Notify

#### NotifyIkachan — **Supported (external)**

`notify/ikachan.rb`. Posts each item to an IRC channel through an `ikachan`
HTTP-to-IRC gateway, joining the channel first. The gateway is software the
operator runs; there is no service to be shut down.

| Key | Type | Meaning |
| --- | --- | --- |
| `url` | string | Gateway base URL. Required. |
| `port` | integer | Gateway port. Default `4979`. |
| `channels` | string | Comma-separated; a leading `#` is added if absent. Required. |
| `command` | string | `notice` or `privmsg`. Default `notice`. |
| `interval` | integer | Seconds between posts. Default `0`. |

Honours a `PROXY` environment variable, on port 8080. A gateway reached over
`https` is spoken to over `https`; the connection used to be plain whatever the
URL said. The channel and the message are form-encoded rather than interpolated
into the request body, so an item whose title carries an `&` or a space reaches
the channel whole instead of splitting the request.

### 6.7 Publish

Send the result outward, or print it. Normally last in a Recipe. This is where
the pipeline is written out in a form that is not the pipeline's own, so each of
these plugins is a serializer as much as a destination.

#### PublishMarkdown — **Supported**

`publish/markdown.rb`. Renders the pipeline as a Markdown document and writes it
to standard output or to a file. It needs no service, no account and no
credential, which is what makes it the plugin a Recipe can end with on any
machine, and the one to reach for when the result is meant to be read later —
by a person, by `grep`, by whatever is given the file next.

```yaml
  - module: PublishMarkdown
    config:
      file: ~/notes/feeds.md
      mode: append
```

| Key | Type | Meaning |
| --- | --- | --- |
| `file` | string | Path of the file to write. `~` is expanded and a missing parent directory is created. Absent: standard output. |
| `mode` | string | `append`, the default, or `overwrite`. Read only when `file` is set. |

Both are optional: `PublishMarkdown` with no `config` writes the document to
standard output.

##### What it writes

One section per item, in pipeline order — the feeds in the order they arrive,
the items in the order their feed carries them. Nothing sorts, groups or
de-duplicates here; `FilterSort` and the store plugins are where that belongs.

```markdown
## An item's title

- Link: <https://example.com/a>
- Date: 2026-08-14 10:00:00 +0900
- Author: someone@example.com

The body of the item, as text.
```

- **The title is a level-2 ATX heading**, and that heading is the item boundary:
  a section starts at `## ` and runs to the next one. An item with no title uses
  its link as the heading, and an item with neither is headed `(untitled)`.
  Level 2 rather than level 1, so that a document these sections are collected
  into can carry a title of its own.
- **The metadata list** follows the heading: one `- Field: value` bullet per
  field the item carries, in the fixed order `Link`, `Date`, `Author`,
  `Comments`, `Source`, `Enclosure`. A field that is `nil` or empty produces no
  bullet, and an item carrying none produces no list. URLs are written as
  autolinks — `<https://example.com/a>` — so that a renderer makes them links
  and `grep` still sees the URL.
- **The body** is `content_encoded` when the item has one, and `description`
  otherwise, on the ground that a feed carrying both puts the summary in the
  second and the article in the first. An item with neither has no body, and its
  section is the heading and the metadata list.
- **The date** is formatted `%Y-%m-%d %H:%M:%S %z` from the item's own date, in
  the zone that date carries. Nothing is converted to local time, because the
  same input then produces the same output on any machine.
- **`source` and `enclosure` are elements rather than strings** in a parsed
  feed. The source's text is used, and the enclosure's URL; where either is
  already a plain string it is used as it stands.
- **A section is followed by a blank line.** Appending a document to a document
  therefore stays valid Markdown, and a file always ends with a newline.
- **Nothing else is emitted.** No YAML front matter, no run header, no
  timestamp of the run, no horizontal rules — nothing that is not in the
  pipeline. The output for a given pipeline is byte-for-byte the same on every
  run, which is what makes it worth committing and diffing. A format is easy to
  add later and impossible to take away, so this one starts as ordinary
  Markdown and no more.
- **An empty pipeline writes nothing at all**: no file is created, and an
  existing file is neither appended to nor truncated. A run in which the store
  plugin found nothing new leaves the document exactly as it was.

##### HTML in a body

`description` and `content_encoded` carry HTML in most real feeds, and a
document that dumped it unchanged would be HTML in a file named `.md` rather
than Markdown. What the plugin does instead:

- A body with no markup in it is passed through as it stands.
- A body containing markup is **reduced to text**: `script` and `style` are
  dropped with their contents, `<br>` becomes a line break, block elements
  become paragraph breaks, character entities are decoded, and the tags
  themselves are discarded.
- In both cases the whitespace is normalized: line endings become `\n`,
  trailing whitespace goes, and a run of blank lines collapses to one. Text
  that came from markup also loses the source document's own indentation, which
  is layout rather than content and which Markdown would otherwise read as a
  code block.

This is deliberately **not** an HTML-to-Markdown translation. Rendering
arbitrary markup back into equivalent Markdown — tables, nested lists, inline
links, images — is a large job with a large library behind it, and a library
that size does not become a dependency for one plugin
([`POLICY.md`](POLICY.md) section 9.1). The result is defined by its two ends —
the text survives, the markup does not — which is what both a reader and a
program reading the file want from it. A link inside a body becomes its own
text; the item's own link is in the metadata list, where nothing loses it.

**This plugin needs no gem of its own.** It uses `nokogiri` to reduce a body
where `nokogiri` is installed, and reduces it with its own substitution where it
is not, so that a Recipe ending here runs on a plain `gem install automatic` and
no Recipe pays for an HTML parser it did not ask for. The two produce the same
document for the bodies a feed carries; a parser is simply better at markup that
is badly malformed, which is the reason to install `nokogiri` if you publish
from feeds that produce it. The specs hold both to the same output.

Where a different treatment is wanted, the pipeline already has the means:
`FilterSanitize` before this plugin decides what markup survives into the
description, and this plugin then reduces what is left.

The body is otherwise written as it is: Markdown is **not** escaped, so a body
line beginning with `#` or `-` renders as a heading or a list item. Escaping it
would make the text worse to read in exchange for a rendering nothing depends
on.

##### Where the output goes

With `file`, the document is written there, appended by default so that a
Recipe in `cron` builds up one growing document, and `mode: overwrite` replaces
the file when what is wanted is the current state rather than a history. The
plugin writes only that file, and only what its `config` names.

With no `file`, the document goes to standard output, which is what a pipe or a
shell redirect wants:

```sh
automatic -c feeds.yml > today.md
```

Standard output is also where `Automatic::Log` writes
([`REQUIREMENTS.md`](REQUIREMENTS.md) section 14), so a redirect collects the
log lines into the document as well. Set the log level for that Recipe, which
is the setting that already exists for it:

```yaml
global:
  log:
    level: none

plugins:
  # ...
  - module: PublishMarkdown
```

`file` avoids the question entirely: the document goes to the file and the log
keeps standard output. Which to use is an operational choice and
[`DEPLOYMENT.md`](DEPLOYMENT.md) says more about it.

The plugin logs one line per run at `info`, naming the destination and the
number of items written; it does not log a line per item, because that log is
what would be interleaved with the document.

#### PublishConsole — **Supported**

`publish/console.rb`. Prints each item with `pretty_inspect`. The plugin to end
a Recipe with while writing it. No settings.

#### PublishConsoleLink — **Supported**

`publish/console_link.rb`. Prints each item's link, one per line, and nothing
else. Useful in a pipe. No settings.

#### PublishEject — **Supported (external)**

`publish/eject.rb`. Opens and closes the optical drive once per item, using
`eject` on GNU/Linux or `drutil` on macOS. A physical notification. Needs the
command to exist.

| Key | Type | Meaning |
| --- | --- | --- |
| `interval` | integer | Seconds between items. Default `0`. |

#### PublishMemcached — **Supported (external)**

`publish/memcached.rb`. Collects the whole pipeline into one hash keyed by link
and stores it under a single key. Needs the `dalli` gem and a memcached server.

| Key | Type | Meaning |
| --- | --- | --- |
| `host` | string | memcached host. Required. |
| `port` | string or integer | memcached port. Required. |
| `key` | string | The key to store under. Required. |

`port: 11211` written as a number now works. The server address was built by
concatenating strings, so a Recipe that did not quote the port ended the run
with a `TypeError`.

It writes one key per run, replacing the previous value. `key` collides with a
`Hashie::Mash` built-in and logs a warning per run; the setting works, see
section 2.6.1.

#### PublishFluentd — **Supported (external)**

`publish/fluentd.rb`. Posts each item's title, link, description,
`content_encoded` and a timestamp to Fluentd. Needs the `fluent-logger` gem and
a Fluentd instance.

| Key | Type | Meaning |
| --- | --- | --- |
| `host` | string | Fluentd host |
| `port` | integer | Fluentd port |
| `tag` | string | Tag, for example `automatic.feed` |
| `mode` | string | `test` builds no connection and sends nothing |

#### PublishInstapaper — **Supported (external)**

`publish/instapaper.rb`. Adds each item to Instapaper through its Simple API,
with HTTP basic authentication over TLS.

| Key | Type | Meaning |
| --- | --- | --- |
| `email` | string | Account. Required. |
| `password` | string | Password; may be empty for an account without one. |
| `retry` | integer | Attempts after the first. Default `0`. |
| `interval` | integer | Seconds between posts. Default `0`. |

The Simple API is still published at `www.instapaper.com/api/simple` and takes
the same three parameters this sends. The status rests on that published
documentation rather than on a live call with an account, so run
`test/integration/test_instapaper.yml` once before putting it in `cron`.

Constructing the plugin authenticates, so a wrong credential fails the run
before any item is posted rather than once per item. Nothing logs the account
or the password. This plugin used to disable TLS certificate verification,
which was corrected in the previous release; the connection now also has a
timeout, so an unanswered request ends rather than hanging a `cron` job.

#### PublishAmazonS3 — **Supported (external)**

`publish/amazon_s3.rb`. Uploads files whose link is a `file://` URI to S3,
normally after `StoreFile`.

| Key | Type | Meaning |
| --- | --- | --- |
| `access_key` | string | Access key ID. Omit to use the SDK's own credential chain. |
| `secret_key` | string | Secret access key. |
| `bucket_name` | string | Bucket. |
| `target_path` | string | Prefix within the bucket. |
| `region` | string | Omit to use the SDK's own resolution. |
| `mode` | string | `test` logs the upload without performing it. |

Migrated from `AWS::S3`, which only AWS SDK for Ruby version 1 provided, to
`Aws::S3::Client` from **version 3** — the `aws-sdk-s3` gem, which is the SDK
AWS publishes and maintains. The Recipe keys are unchanged; `region` is new and
optional. The gem is an optional plugin dependency and is required only when an
upload is actually made, so `mode: test` needs neither the gem nor an account:
`gem install aws-sdk-s3`, or the `s3` group in a checkout.

Leaving `access_key` and `secret_key` out is now the better way to run this. The
SDK then resolves credentials from the environment, a shared profile or an
instance role, which keeps a long-lived secret out of the Recipe file.

#### PublishHatenaBookmark — **Needs rework**

`publish/hatena_bookmark.rb`. Bookmarks each link to Hatena Bookmark by posting
an Atom entry with WSSE authentication to `b.hatena.ne.jp/atom/post`.

Hatena Bookmark is operating and has a current bookmarking API; the WSSE
AtomPub interface this speaks has been superseded by an OAuth one, and Hatena's
own documentation no longer describes WSSE for this API. Restoring the plugin
means the current endpoint and the current authentication, which is a
credential format this Recipe cannot express: consumer key and secret plus an
access token and secret, obtained through an authorization flow, in place of an
ID and a password. That is a self-contained piece of work and it is why this is
not classified any higher.

The transport was corrected in the meantime: the request goes over HTTPS, so an
operator who runs it does not put a password digest on the wire in the clear,
and the nonce is drawn from a random source rather than from the clock. Neither
is a claim that the plugin works.

| Key | Type | Meaning |
| --- | --- | --- |
| `username` | string | Hatena ID |
| `password` | string | Password |
| `interval` | integer | Seconds between posts. Default `0`. |

---

## 7. Summary

| Status | Count | Plugins |
| --- | --- | --- |
| Supported | 26 | `SubscriptionFeed`, `SubscriptionLink`, `SubscriptionXml`, `SubscriptionText`, `CustomFeedWeb`, `FilterIgnore`, `FilterAccept`, `FilterSort`, `FilterOne`, `FilterRand`, `FilterClear`, `FilterImage`, `FilterImageSource`, `FilterAbsoluteURI`, `FilterSanitize`, `FilterTumblrResize`, `FilterDescriptionLink`, `FilterGithubFeed`, `FilterJoin`, `StorePermalink`, `StoreFullText`, `StoreDigest`, `StoreFile`, `PublishMarkdown`, `PublishConsole`, `PublishConsoleLink` |
| Supported (external) | 14 | `SubscriptionTumblr`, `CustomFeedSVNLog`, `FilterFullFeed`, `FilterOpenAI`, `FilterClaude`, `FilterGemini`, `FilterSakuraAI`, `ProvideFluentd`, `NotifyIkachan`, `PublishEject`, `PublishMemcached`, `PublishFluentd`, `PublishInstapaper`, `PublishAmazonS3` |
| Needs rework | 1 | `PublishHatenaBookmark` |

Forty-one plugins. Every one of them either runs, or names the one thing it
needs from the operator; the single exception says what is wrong with it and
what fixing it would take.

`spec/doc/plugins_catalogue_spec.rb` holds this table to the files in
`plugins/`: an entry with no file, a file with no entry, and a count that has
been left behind by an edit are all failures of the ordinary test suite.

## 8. Plugins that were removed

Eleven plugins were removed in v26.08 rather than kept as history. Each one
talked to a service that has shut down, or through an API that has been
withdrawn with no replacement that a plugin this size can reach:

| Removed | Why |
| --- | --- |
| `SubscriptionTwitter`, `SubscriptionTwitterSearch`, `PublishTwitter` | Written against the `twitter` gem's version 4 interface and against `twitter.com` markup from 2014. The site is X, the gem's classes are gone, and the current API has no free tier — posting and searching are billed per call. |
| `SubscriptionPocket`, `PublishPocket` | Pocket was shut down by Mozilla on 8 July 2025 and its API with it. |
| `PublishHipchat` | Atlassian discontinued HipChat and shut the service down in February 2019; there is no endpoint. |
| `PublishGoogleCalendar` | Speaks the Calendar GData API version 2 with ClientLogin, shut down in November 2014 and April 2015, through a gem last published in 2009. |
| `SubscriptionWeather` | livedoor Weather Hacks ended on 31 July 2020, through a gem last published in 2013. |
| `SubscriptionGGuide`, `SubscriptionChanToru` | So-net's "Gガイド.テレビ王国 Chan-Toru" ended on 31 July 2020 and the business was transferred; the RSS endpoint is gone. |
| `FilterGoogleNews` | Unwrapped a Google News link by reading whatever followed `&url=`. Google News now emits opaque `/rss/articles/…` links whose destination is only obtainable from an undocumented internal endpoint. |

The reason for removing rather than marking them is in section 5: a plugin ships
because it has a current use. Git history holds the implementations, and a
Recipe naming one of these now fails at load with `Automatic::NoPluginError`
before anything runs — which is a clearer answer than a plugin that runs and
does nothing.

Their integration Recipes, specs and optional dependencies went with them. The
`xml-simple` and `nkf` dependencies also went, from plugins that were kept: see
sections 6.2 and 6.3.
