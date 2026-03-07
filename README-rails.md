# manticore-rails

ActiveRecord integration for [Manticore Search](https://manticoresearch.com) with a ThinkingSphinx-style DSL.

Part of the [manticore-client](https://github.com/numbata/manticore-client) project.

## Installation

```ruby
# Gemfile
gem "manticore-rails", "~> 0.1"
```

This pulls in `manticore-client` (the HTTP layer) automatically.

Then run the generator to create an initializer:

```bash
rails g manticore:install
```

## Quick start

```ruby
# config/initializers/manticore.rb

ManticoreClient::Client.configure do |config|
  config.host = ENV.fetch("MANTICORESEARCH_URL", "http://127.0.0.1:9308")
end

ManticoreRails.configure do |config|
  config.index_prefix = Rails.env.test? ? "test_" : nil
  config.batch_size = 1000
  config.auto_indexing = true
  config.async_indexing = false
end
```

```ruby
class Article < ApplicationRecord
  include ManticoreRails::Searchable

  define_manticore_index do
    indexes :title
    indexes :body
    indexes tags.name, as: :tag_names

    has :id, type: :integer
    has :status, type: :integer
    has :published_at, type: :datetime
  end
end
```

```bash
rake manticore:setup  # creates tables and populates indexes
```

```ruby
Article.search("ruby", with: { status: 1 }, page: 1, per_page: 20)
```

## Index definition

Include `ManticoreRails::Searchable` and define your index with `define_manticore_index`:

```ruby
define_manticore_index do
  # Full-text fields — searchable via Article.search("query")
  indexes :title
  indexes :body

  # Association fields — dot notation, values joined with spaces
  indexes tags.name, as: :tag_names         # has_many
  indexes author.name, as: :author_name     # belongs_to

  # Attributes — filterable and sortable, not full-text searched
  has :id, type: :integer
  has :status, type: :integer
  has :published_at, type: :datetime
  has :featured, type: :boolean

  # Reindex parent record when associated records change
  reindex_on_change :tags
end
```

### Custom serialization

Override `manticore_serialize` to control the indexed document. Required when your index uses SQL placeholders or computed values:

```ruby
def manticore_serialize
  {
    "id" => id,
    "title" => title,
    "tag_names" => tags.pluck(:name).join(" "),
    "summary" => compute_summary,
    "status" => status || 0,
    "published_at" => published_at&.to_i || 0
  }.compact
end
```

When defined, this replaces the default field-walking serialization entirely.

### Type mapping

| Ruby type    | Manticore type |
|-------------|----------------|
| `:integer`  | `bigint`       |
| `:datetime` | `timestamp`    |
| `:boolean`  | `bool`         |
| `:float`    | `float`        |
| `:string`   | `string`       |
| `:text`     | `text`         |
| `:json`     | `json`         |

## Search

```ruby
# Full-text
Article.search("ruby on rails")

# Filters
Article.search("ruby", with: { status: 1 })
Article.search("ruby", with: { status: [1, 2] })                          # IN
Article.search("", with: { published_at: 1.week.ago.to_i..Time.current.to_i }) # range
Article.search("ruby", without: { status: 0 })                            # exclusion

# Sorting
Article.search("ruby", order: { published_at: :desc })
Article.search("ruby", order: "published_at DESC")

# Pagination
results = Article.search("ruby", page: 2, per_page: 20)
results.total_entries  # => 156
results.total_pages    # => 8
results.current_page   # => 2
results.next_page      # => 3
results.previous_page  # => 1

# IDs only (skips model loading)
Article.search_for_ids("ruby", with: { status: 1 })
```

## Auto-indexing

With `auto_indexing: true` (the default), records are indexed and removed via `after_commit` callbacks. Disable temporarily for bulk operations:

```ruby
ManticoreRails.no_auto_indexing do
  Article.insert_all(big_batch)
end

ManticoreRails::Indexer.new(Article.manticore_index).reindex_all
```

### Async indexing

For background indexing, set `async_indexing: true` and provide a job class:

```ruby
ManticoreRails.configure do |config|
  config.async_indexing = true
  config.index_job_class = "ManticoreIndexJob"
end
```

The job class receives `(action, class_name, id)` and should call the indexer accordingly.

## Rake tasks

```bash
rake manticore:setup                     # drop + create + populate all indexes

rake manticore:schema:create             # create ManticoreSearch tables
rake manticore:schema:drop               # drop ManticoreSearch tables
rake manticore:schema:rebuild            # drop + create

rake manticore:index:rebuild             # reindex all tables
rake manticore:index:rebuild[articles]   # reindex specific table
```

**Note:** `manticore:setup` and `manticore:schema:rebuild` drop and recreate tables, causing brief downtime for search queries. For zero-downtime schema changes, create a new table with a versioned name, populate it, then swap via application config. This is not yet automated.

## Table properties

Use `set_property` to pass ManticoreSearch table options:

```ruby
define_manticore_index do
  indexes :title
  indexes :body

  set_property min_infix_len: 3
  set_property morphology: "stem_en"
end
```

Properties are appended to the `CREATE TABLE` statement as `key = 'value'` pairs.

## Error handling

By default, indexing errors are reported via `warn`. Configure a custom handler for production:

```ruby
ManticoreRails.configure do |config|
  config.on_error = ->(message, error) {
    Rails.logger.error("[ManticoreRails] #{message}: #{error.message}")
    Sentry.capture_exception(error) if defined?(Sentry)
  }
end
```

The callback receives `(message, error)` and is invoked for indexing failures, bulk operation errors, and callback setup issues.

## Health check

```ruby
ManticoreRails.healthy?  # => true / false
```

Returns `true` if ManticoreSearch is reachable, `false` on any connection error.

## Instrumentation

When `ActiveSupport::Notifications` is available, ManticoreRails emits events you can subscribe to:

| Event | Payload | When |
|-------|---------|------|
| `search.manticore_rails` | `{ table: }` | Every search query |
| `bulk.manticore_rails` | `{ table:, count: }` | Bulk replace (index) operations |
| `delete.manticore_rails` | `{ table:, count: }` | Bulk delete operations |

```ruby
ActiveSupport::Notifications.subscribe("search.manticore_rails") do |name, start, finish, id, payload|
  Rails.logger.info "[Manticore] #{payload[:table]} search took #{finish - start}s"
end

ActiveSupport::Notifications.subscribe("bulk.manticore_rails") do |name, start, finish, id, payload|
  Rails.logger.info "[Manticore] Indexed #{payload[:count]} docs into #{payload[:table]}"
end
```

## Circuit breaker

ManticoreRails tracks consecutive indexing failures and stops attempting to index after reaching `circuit_breaker_threshold` (default: 10). This prevents a ManticoreSearch outage from slowing down every ActiveRecord save.

The circuit resets automatically on the next successful indexing operation. To manually reset it (e.g. after ManticoreSearch recovers):

```ruby
ManticoreRails.reset_circuit!
```

```ruby
ManticoreRails.configure do |config|
  config.circuit_breaker_threshold = 10  # stop after 10 consecutive failures
end

ManticoreRails.circuit_open?  # => true/false
```

## Configuration reference

```ruby
ManticoreRails.configure do |config|
  config.index_prefix              = nil    # prefix for table names (e.g. "test_")
  config.batch_size                = 1000   # records per batch during reindex
  config.auto_indexing             = true   # after_commit index/remove callbacks
  config.async_indexing            = false  # delegate indexing to a background job
  config.index_job_class           = nil    # job class name (string) for async mode
  config.circuit_breaker_threshold = 10     # consecutive failures before circuit opens
  config.on_error = ->(msg, err) { warn "[ManticoreRails] #{msg}: #{err.message}" }
  # config.on_error = :raise              # re-raise errors (useful in dev/test)
end
```

## Troubleshooting

**ManticoreSearch is not running / connection refused**

```ruby
ManticoreRails.healthy?  # => false
```

Ensure ManticoreSearch is running and `MANTICORESEARCH_URL` points to the correct host.

**Table doesn't exist after adding fields**

After changing `define_manticore_index`, rebuild the schema:

```bash
rake manticore:schema:rebuild
rake manticore:index:rebuild
```

**Reindex a single record**

```ruby
Article.manticore_indexer.index_records([article.id])
```

**Search returns stale data**

Associated record changes only trigger reindexing if `reindex_on_change` is declared and the association has an `inverse_of`. Verify both are set.

**High memory during reindex with large associations**

`find_in_batches` with `includes` loads all associated records per batch. For high-cardinality associations (e.g., thousands of tags per record), reduce `batch_size` or use `manticore_serialize` to control the query.

## License

MIT. See [LICENSE.txt](LICENSE.txt).
