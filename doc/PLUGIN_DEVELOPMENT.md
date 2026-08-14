# Plugin Development

A plugin is a small Ruby class with `initialize` and `run`. It needs no registry,
framework edit or dependency-injection container.

To add or change a plugin in this repository, first follow the
[source checkout setup](../README.md#from-a-checkout), including `bundle
install` and the default test suite. User plugins under `~/.automatic` do not
require a framework checkout.

## Naming and location

The class name combines a category and a name. The file path separates them:

```text
FilterTitlePrefix -> filter/title_prefix.rb
```

Shipped plugins live under `plugins/`. A user plugin lives under
`~/.automatic/plugins/` and is found before a shipped plugin with the same name.

## A complete plugin

Create `~/.automatic/plugins/filter/title_prefix.rb`:

```ruby
module Automatic::Plugin
  class FilterTitlePrefix
    def initialize(config, pipeline = [])
      @config = config || {}
      @pipeline = pipeline
    end

    def run
      prefix = @config['prefix'].to_s
      @pipeline.each do |feed|
        next if feed.nil?

        feed.items.each do |item|
          item.title = "#{prefix}#{item.title}"
        end
      end
      @pipeline
    end
  end
end
```

Use it in any Recipe:

```yaml
- module: FilterTitlePrefix
  config:
    prefix: "[News] "
```

No framework source or registry is changed. The loader derives the file path
from `FilterTitlePrefix` and loads it from the user plugin directory.

## The contract

- Put the class in `Automatic::Plugin`.
- Choose one existing category: `Subscription`, `CustomFeed`, `Filter`, `Store`,
  `Provide`, `Notify` or `Publish`.
- Accept `(config, pipeline)` in `initialize`; tolerate a missing config.
- Read config by string key, because it comes from YAML.
- Implement `run` and return the shared pipeline value.
- Use `Automatic::Log.puts('info', 'message')` for useful operational events.
  Never log credentials or one noisy line per routine transformation.
- Require an external gem at the top of the plugin file. A dependency used by
  one optional plugin does not belong in the framework gemspec.

A source plugin creates feed objects. A Filter or Store changes or narrows them.
A Publish plugin serializes or sends them, then still returns the pipeline.

## Test it without a network

Construct a pipeline with `Automatic::FeedMaker`, run the class directly and
assert on its returned items. Use fixed input and temporary directories. The
default suite must not contact a real host, use a credential or depend on the
clock. Put an explicitly tagged integration check outside the default suite if
the plugin must also be exercised against a live service.

The repository's loader specs demonstrate that a plugin placed under the user
directory is discoverable. The plugin catalogue and complete contract are in
[`PLUGINS.md`](PLUGINS.md).
