# AI Tutorial

This tutorial builds one Recipe that reads a set of public index pages, collects
the articles they list, turns them into a single text, asks an AI service one
question about that text, and writes the answer out as Markdown. It is built up
one plugin at a time, and every stage in between is a Recipe that runs and
produces something a person can read.

It assumes [`QUICKSTART.md`](QUICKSTART.md) has been followed once, so that
`automatic` runs, `~/.automatic` exists, and the habit of asking "which plugins
does this Recipe name, and what do they need" is already in place. What each
plugin does in full is [`PLUGINS.md`](PLUGINS.md) section 6; this document is
the order they go in and why.

One claim is worth stating before the first Recipe, because it is what the
tutorial is for:

**An AI filter is one filter in a pipeline.** It has no privileged position, it
is not the point of the Recipe, and it is not what makes the Recipe useful. It
takes a text, returns a text, and sits between two plugins that neither know nor
care that it is there. Everything before it is worth running on its own, and the
whole design follows from that.

## 1. The finished shape

This is where the tutorial ends:

```text
CustomFeedWeb        find the articles the index pages list
      ↓
StorePermalink       drop the links already seen
      ↓
FilterFullFeed       replace each summary with the article body
      ↓
FilterSanitize       reduce the body to plain text
      ↓
FilterJoin           make one text out of every article
      ↓
FilterSakuraAI       ask one question about that text
      ↓
PublishMarkdown      write the answer to a document
```

Seven plugins, each doing one thing, each handing its result to the next. The
Recipe that expresses it is in section 4, and nothing in it is a special case:
every entry is a plugin the framework loads by name, and the order of the list
is the order of the work.

The store plugin's position is not an aesthetic choice. `FilterJoin` produces
one item with **no link** — it is several articles at once, so there is no page
it points at — and the store plugins are keyed on the link and drop an item
without one. `StorePermalink`, `StoreFullText` and `StoreDigest` therefore
belong **before** `FilterJoin`, where there is still one item per article to
record. Put one after it and the Recipe stores nothing and publishes nothing.

## 2. Build it without AI first

Write this to `~/.automatic/config/ai-digest.yml`. It is the finished Recipe
without `FilterJoin` and without the AI filter:

```yaml
plugins:
  - module: CustomFeedWeb
    config:
      retry: 2
      interval: 2
      sites:
        - name: Python Insider
          url: https://blog.python.org/
          link_selector: 'a[href]'
          include:
            - '^https://blog\.python\.org/20[0-9]{2}/[0-9]{2}/[^/]+/?$'
          fetch_items: 20

        - name: Rust Blog
          url: https://blog.rust-lang.org/
          link_selector: 'a[href]'
          include:
            - '^https://blog\.rust-lang\.org/20[0-9]{2}/[0-9]{2}/[0-9]{2}/[^/]+/?$'
          fetch_items: 20

        - name: The Go Blog
          url: https://go.dev/blog/
          link_selector: 'a[href]'
          include:
            - '^https://go\.dev/blog/[^/]+$'
          fetch_items: 20

  - module: StorePermalink
    config:
      db: ai-digest.db

  - module: FilterFullFeed
    config:
      siteinfo: items_all.json

  - module: FilterSanitize
    config:
      mode: restricted

  - module: PublishMarkdown
    config:
      file: ~/.automatic/markdown/ai-digest.md
      mode: append
```

What each plugin is responsible for, and nothing more than that:

- **`CustomFeedWeb`** makes one HTTP request per site, reads the index page as
  HTML, and builds a feed from the article links it lists. `include` is what
  tells an article from a navigation link. It does not follow those links and
  does not read an article body.
- **`StorePermalink`** records each item's link in SQLite and passes on only the
  links it had not recorded already. It is what makes the Recipe safe to run
  from `cron`, and — put here, ahead of everything that costs anything — it is
  also what keeps the later plugins from working on an article twice. `db` is a
  file name under `~/.automatic/db`.
- **`FilterFullFeed`** takes the link of each surviving item, finds a siteinfo
  record whose URL pattern matches it, fetches the page, and replaces the
  summary with the body that record's XPath selects.
- **`FilterSanitize`** strips the markup out of the description, leaving text.
- **`PublishMarkdown`** writes one level-2 heading per item, with its metadata
  and its body, to a document.

The Recipe's dependencies are the union of its plugins', as always:
`CustomFeedWeb` and `FilterFullFeed` need `nokogiri`, `StorePermalink` needs
`activerecord` and `sqlite3`, `FilterSanitize` needs `sanitize`, and
`PublishMarkdown` needs nothing of its own.

```sh
gem install nokogiri
gem install activerecord sqlite3
gem install sanitize
```

In a checkout the same three groups are selected together:

```sh
bundle config set --local with "html store sanitize"
bundle install
```

Run it, then read what it wrote:

```sh
automatic -c ~/.automatic/config/ai-digest.yml
sed -n '1,60p' ~/.automatic/markdown/ai-digest.md
```

**What comes out is already useful**, and that is the first point of the
exercise. The document holds one section per new article, with its title, its
link, its date and whatever text the pipeline could get. No AI service has been
contacted, no credential exists yet, and the Recipe is complete in itself: a
person who only ever wanted this can stop here and put it in `cron`.

**Expect `FilterFullFeed` to find nothing for these three sites, and read the
log to see it.** The shipped `assets/siteinfo/items_all.json` is a snapshot of
the LDRFullFeed database whose newest entries are from 2013, and none of its URL
patterns matches these sites:

```text
Fulltext SITEINFO not found: https://go.dev/blog/pkgsite-api
```

Where no record matches, the plugin leaves the item exactly as it arrived, and
the run continues. That is the behaviour to rely on and also the reason the
document above holds a title, a link and a date per article and no body: an
index page read without a `description_selector` carries no description for
`FilterFullFeed` to have improved on.

Getting text into these items is a choice between two places, and both are
configuration rather than code:

- **From the index page.** Where the listing prints a summary, an
  `item_selector` marking one article's node with a `description_selector`
  inside it puts that summary in the item. `CustomFeedWeb` requires the first to
  use the second, because without a node there is nothing to read the summary
  in.
- **From the article.** Supply your own siteinfo file in
  `~/.automatic/assets/siteinfo/`, with the URL patterns and XPaths of the sites
  you actually read, and `FilterFullFeed` fetches each page and puts its body in
  the item.

The rest of this tutorial holds either way: what follows cares that each item
carries text, not where the text came from. It is worth having one of the two
working before the AI filter is added, because a joined text of titles and URLs
is what a summary of nothing looks like.

Read the log rather than only the document. It names each page fetched, each
link stored, each siteinfo lookup that missed, and the file written. Every stage
below is judged the same way.

## 3. Make one text out of many items

Add `FilterJoin` between `FilterSanitize` and `PublishMarkdown`:

```yaml
  - module: FilterJoin
    config:
      title: Daily Digest
```

Run it again and the document changes shape. Where the previous run wrote one
section per article, this one writes a single section titled `Daily Digest`,
whose body holds every article in sequence:

```text
ARTICLE 1
Title: Enabling Polonius on nightly
URL: https://blog.rust-lang.org/2026/08/04/enabling-polonius-alpha-on-nightly/

The body of the first article.

ARTICLE 2
Title: Extending the pkgsite API
URL: https://go.dev/blog/pkgsite-api

The body of the second article.
```

That is the whole of what `FilterJoin` does: many items in, one item out. It
fetches nothing, summarizes nothing, parses no HTML and calls no service. Its
only setting is the title of the item it produces.

It is worth being clear about why this is its own plugin rather than part of
what comes next. Joining a day's release notes, log lines or notifications into
one document is the same operation, and it is useful with no AI service
anywhere in the Recipe. The plugin adds no prompt and knows nothing about what
reads its result; what the joined text is *for* is decided entirely by the
plugin the Recipe puts after it.

Note also what the joined item lost: its link. This is the stage the ordering
rule from section 1 is about, and it is visible in the document — the joined
section carries a title and no `Link` bullet.

## 4. Ask one question about that text

Now the AI filter goes between `FilterJoin` and `PublishMarkdown`:

```yaml
  - module: FilterSakuraAI
    config:
      token: YOUR_SAKURA_AI_TOKEN
      model: gpt-oss-120b
      prompt: |
        以下の記事群について、個別記事の要約を羅列するのではなく、
        全体を一つのダイジェストとして日本語で要約してください。
      retry: 2
      interval: 2
```

The pipeline holds one item, so the service is asked **once**. The `prompt` is
sent as the instruction and the item's description — the joined text from
section 3 — as the text to work on. What comes back replaces the description.
The title stays `Daily Digest`, the item count stays one, and `PublishMarkdown`
writes the answer exactly where the joined text used to be.

The whole Recipe, with the two plugins added since section 2 and the site list
shortened to one site:

```yaml
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
          fetch_items: 20

  - module: StorePermalink
    config:
      db: ai-digest.db

  - module: FilterFullFeed
    config:
      siteinfo: items_all.json

  - module: FilterSanitize
    config:
      mode: restricted

  - module: FilterJoin
    config:
      title: Daily Digest

  - module: FilterSakuraAI
    config:
      token: YOUR_SAKURA_AI_TOKEN
      model: gpt-oss-120b
      prompt: |
        以下の記事群について、個別記事の要約を羅列するのではなく、
        全体を一つのダイジェストとして日本語で要約してください。
      retry: 2
      interval: 2

  - module: PublishMarkdown
    config:
      file: ~/.automatic/markdown/ai-digest.md
      mode: append
```

**The token is a Recipe setting, which makes the Recipe a secret file.** Put the
real token in the file on the machine that runs it, keep the placeholder in
anything you commit, and restrict the file:

```sh
chmod 600 ~/.automatic/config/ai-digest.yml
```

The plugin never logs the token, never puts it in an exception message and never
writes it into an item, and TLS certificates are verified — but a Recipe in a
repository or a world-readable Recipe defeats all of that. `~/.automatic/config`
is not a place to keep files under version control.

**`retry` and `interval` are about the network, not about the answer.** A
timeout, a `429` and a `5xx` are attempted again, up to `retry` times,
`interval` seconds apart. A refused request, an answer that is not JSON, an
answer whose shape is not the documented one, and a missing or wrong setting all
end the run instead, because the next attempt would fail the same way. A missing
`token`, `model` or `prompt` is refused before the first request is made.

A failure never leaves an empty description behind: the run ends rather than
publishing the article as a blank. That is why the stage in section 2 matters —
when the service is unavailable, removing one line from the Recipe returns a
pipeline that still writes a document.

## 5. Swap the order, and the Recipe means something else

Move the AI filter to before `FilterJoin` and change nothing else:

```yaml
  - module: FilterSanitize
    config:
      mode: restricted

  - module: FilterSakuraAI
    config:
      token: YOUR_SAKURA_AI_TOKEN
      model: gpt-oss-120b
      prompt: |
        以下の記事を日本語で三行に要約してください。
      retry: 2
      interval: 2

  - module: FilterJoin
    config:
      title: Daily Digest
```

Every AI filter makes **one request per item**, so with three articles in the
pipeline the two arrangements differ:

| Order | Requests, for three articles | What the answer is |
| --- | --- | --- |
| `FilterJoin` → AI filter | 1 | One text about everything at once |
| AI filter → `FilterJoin` | 3 | Three separate texts, joined afterwards |

Both are legitimate, and they answer different questions. A digest that draws a
theme across the day's articles needs the first; a document of per-article
summaries needs the second. The second is also the one that grows with the feed:
a run that finds forty new articles makes forty requests, each of them billed
and rate-limited. `StorePermalink` earlier in the Recipe is the main defence,
because it means each article is sent once ever; `FilterOne` ahead of the filter
is the blunt one, while a Recipe is being written.

The point is not which order is better. It is that the difference between "one
digest" and "a list of summaries" is the position of one entry in a YAML list,
and that no plugin had to be changed or configured to express it.

## 6. Change the service by changing one line

The four AI filters — `FilterOpenAI`, `FilterClaude`, `FilterGemini` and
`FilterSakuraAI` — are one per service rather than one plugin with a `provider`
setting. Each replaces an item's description with what its service answers, so
in a Recipe they are interchangeable at the same position:

```yaml
  - module: FilterOpenAI
    config:
      token: YOUR_OPENAI_API_KEY
      model: gpt-5.6
      prompt: |
        以下の記事群を一つのダイジェストとして日本語で要約してください。
      retry: 2
      interval: 2
```

```yaml
  - module: FilterClaude
    config:
      token: YOUR_ANTHROPIC_API_KEY
      model: claude-opus-5
      prompt: |
        以下の記事群を一つのダイジェストとして日本語で要約してください。
      max_tokens: 2048
      retry: 2
      interval: 2
```

```yaml
  - module: FilterGemini
    config:
      token: YOUR_GEMINI_API_KEY
      model: gemini-3.5-flash
      prompt: |
        以下の記事群を一つのダイジェストとして日本語で要約してください。
      retry: 2
      interval: 2
```

Nothing before or after the swapped entry changes. `token`, `model` and `prompt`
are required by all four; `max_tokens` exists only for Claude, because that API
requires it. Model names move with the services, so take them from the provider
you are using rather than from this document, and see
[`PLUGINS.md`](PLUGINS.md) section 6.3 for each plugin's endpoint,
authentication and answer handling.

That a Recipe names the service on its face is the reason for four plugins. A
line reading `FilterClaude` says where the text is going, which is a question
worth being able to answer by reading the Recipe.

## 7. Change the prompt, and the Recipe does another job

None of the four filters is a summarizer. The prompt is the instruction and the
item's description is the text it applies to, so summarizing, translating,
extracting and classifying are the same plugin with different words in one
setting. Keeping the Recipe of section 4 and replacing only the `prompt`:

```yaml
      prompt: |
        以下の記事群から、セキュリティに関係する記述だけを抜き出し、
        日本語の箇条書きにしてください。該当がなければ「該当なし」と答えてください。
```

```yaml
      prompt: |
        Translate the following articles into English, keeping each
        article's heading and order.
```

```yaml
      prompt: |
        以下の記事群を、テーマごとに見出しを付けて分類してください。
        本文の引用はせず、見出しと一行の説明だけを出力してください。
```

There is no default prompt: a Recipe without one is refused rather than being
given a purpose it did not ask for. The instruction and the article text are
sent as separate fields — a system instruction and a user turn — so that what an
article says is text to be worked on rather than an instruction to obey. It is
still worth remembering what the input is: pages fetched from the open web. A
prompt that states what to do when the text does not contain what was asked for
is more robust than one that assumes it does.

**Long input has a limit that belongs to the model, not to the framework.** A
joined text of forty full articles can exceed what a model accepts, and the
service answers with an error that ends the run. Fewer sites, a smaller
`fetch_items`, a stricter `include`, or the per-article arrangement of section 5
are the ways to stay under it with the plugins that ship today. Splitting one
long text into pieces, transforming each and asking a final question about the
results is the natural next arrangement conceptually, and it is **not**
something this repository provides: there is no chunking plugin, and a Recipe
cannot express it today.

## 8. Why it is built this way

Read the finished Recipe again as a shell pipeline and the design is not novel:

```text
discover | deduplicate | fetch | clean | join | transform | write
```

Each plugin takes the pipeline, does one thing to it, and hands it on. The
interface between two plugins is items carrying text, which is why the AI filter
needed no cooperation from `FilterJoin` and why `PublishMarkdown` needed none
from either.

What that buys, concretely:

- **Every prefix of the Recipe is a working Recipe.** Section 2 publishes
  articles, section 3 publishes a joined document, section 4 publishes an
  answer. When the last stage fails, the earlier ones still say what the run
  found.
- **A failure has one address.** Nothing was fetched is `CustomFeedWeb`;
  everything is a summary is `FilterFullFeed` and its siteinfo; the document is
  one section is `FilterJoin`; the request was refused is the AI filter. A
  single plugin that did all of it would have one log and one place to guess in.
- **Changing behaviour is editing configuration, not code.** A different
  service, a different job, one digest instead of many summaries: three edits to
  one YAML file, each of them one line or one setting.
- **The parts recombine.** `FilterJoin` before a Markdown file, an AI filter
  over a feed that needs no joining, a store plugin with neither: none of these
  is a special case of the others.

The plugin this repository deliberately does not have is the one that would be
easiest to want: a `FilterDigest` that fetches the articles, joins them,
summarizes them and writes the file. It would be quicker to configure once, and
it would be the only way to do any of it. Wanting the joined text without the
summary, or the summary of one feed rather than of a day, or the same articles
sent to a different service, would each be a new setting on it, and its log
would tell you only that "the digest failed".

The AI service is the newest thing in the Recipe and the least special: a filter
that takes a text and returns a text, in a list of filters that do the same.

## Next

Every setting used above, and every plugin that could take a place in this
pipeline, is in [`PLUGINS.md`](PLUGINS.md) section 6 — the Recipe format in
section 2, the AI filters in section 6.3. Installing the optional gems,
scheduling a Recipe and reading its log when it fails is
[`DEPLOYMENT.md`](DEPLOYMENT.md). A filter of your own, in the same shape as the
ones used here, is [`PLUGIN_DEVELOPMENT.md`](PLUGIN_DEVELOPMENT.md).
