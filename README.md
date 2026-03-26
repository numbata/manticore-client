# Manticore Search for Ruby

![RubyGems Version](https://img.shields.io/gem/v/manticore-client)
![CI Status](https://github.com/numbata/manticore-client/actions/workflows/ci.yml/badge.svg)

Ruby gems for [Manticore Search](https://manticoresearch.com):

| Gem | Purpose |
|-----|---------|
| **manticore-client** | HTTP client, auto-generated from the OpenAPI spec |
| **manticore-rails** | ActiveRecord integration: index DSL, search, auto-indexing, rake tasks |

## Installation

```ruby
# Gemfile

# HTTP client only (no Rails dependency)
gem "manticore-client", "~> 1.0"

# Rails integration (pulls in manticore-client automatically)
gem "manticore-rails", "~> 0.1"
```

---

## manticore-client

Low-level HTTP client wrapping the Manticore Search API.

```ruby
require "manticore-client"

ManticoreClient::Client.configure do |config|
  config.host = "http://127.0.0.1:9308"
end

api = ManticoreClient::Client::IndexApi.new

body = <<~NDJSON
  {"insert": {"index": "products", "id": 1, "doc": {"title": "Ruby", "rating": 9.5}}}
  {"insert": {"index": "products", "id": 2, "doc": {"title": "Python", "rating": 8.0}}}
NDJSON

api.bulk(body)
```

| Option     | Default                 | Description                           |
|------------|-------------------------|---------------------------------------|
| `host`     | `http://127.0.0.1:9308` | Base URL for the Manticore Search API |
| `username` | *nil*                   | HTTP Basic auth username              |
| `password` | *nil*                   | HTTP Basic auth password              |
| `timeout`  | `60`                    | HTTP request timeout in seconds       |

Full API and model docs are in [docs/](docs/).

---

## manticore-rails

ActiveRecord integration with a ThinkingSphinx-style DSL.

### Setup

```ruby
# config/initializers/manticore.rb

ManticoreClient::Client.configure do |config|
  config.host = ENV.fetch("MANTICORESEARCH_URI", "http://127.0.0.1:9308")
end

ManticoreRails.configure do |config|
  config.index_prefix = Rails.env.test? ? "test" : nil
  config.batch_size = 1000        # records per batch during reindex
  config.auto_indexing = true     # after_commit callbacks
  config.async_indexing = false   # set true + index_job_class for background
  # config.index_job_class = "ManticoreIndexJob"
end
```

### Defining indexes

```ruby
class Article < ApplicationRecord
  include ManticoreRails::Searchable

  define_manticore_index do
    # Full-text fields
    indexes :title
    indexes :body
    indexes tags.name, as: :tag_names    # has_many :tags
    indexes author.name, as: :author_name # belongs_to :author

    # Attributes (filterable, sortable)
    has :id, type: :integer
    has :status, type: :integer
    has :published_at, type: :datetime
    has :featured, type: :boolean

    # Reindex when associated records change
    reindex_on_change :tags

    # Eager-load associations not used as fields but needed for manticore_serialize
    includes :comments
  end
end
```

`indexes` declares full-text searchable fields. `has` declares attributes for filtering and sorting. Association fields use dot notation — values are collected and joined with spaces.

#### Custom serialization

Override `manticore_serialize` to control exactly what gets indexed. This is required when your index includes SQL placeholders or computed values:

```ruby
define_manticore_index do
  indexes :title
  indexes "(SELECT 1)", as: :summary  # SQL placeholder — value comes from serialize
  has :id, type: :integer
  has :published_at, type: :datetime
end

def manticore_serialize
  {
    "id" => id,
    "title" => title,
    "summary" => generate_summary,
    "published_at" => published_at&.to_i || 0
  }.compact
end
```

When `manticore_serialize` is defined, it replaces the default field-walking serialization entirely.

### Searching

```ruby
# Full-text search
results = Article.search("ruby")

# Filters
results = Article.search("ruby", with: { status: 1 })
results = Article.search("ruby", with: { status: [1, 2] })             # IN
results = Article.search("", with: { published_at: 1.week.ago.to_i..Time.current.to_i }) # range
results = Article.search("ruby", without: { status: 0 })               # exclusion

# Sorting
results = Article.search("ruby", order: { published_at: :desc })
results = Article.search("ruby", order: "published_at DESC")

# Pagination
results = Article.search("ruby", page: 2, per_page: 20)
results.total_entries  # => 156
results.total_pages    # => 8
results.current_page   # => 2

# IDs only (skips model loading)
ids = Article.search_for_ids("ruby", with: { status: 1 })

# Facets — term counts per attribute field
results = Article.search("ruby")
counts = results.facets(:status, :featured)
# => { status: { "1" => 42, "0" => 8 }, featured: { "true" => 12 } }
```

### Auto-indexing

Records are indexed and removed automatically via `after_commit` callbacks when `auto_indexing` is enabled (the default). Disable temporarily for bulk operations:

```ruby
ManticoreRails.no_auto_indexing do
  Article.insert_all(big_batch)
end

# Then reindex in bulk
ManticoreRails::Indexer.new(Article.manticore_index).reindex_all
```

### Rake tasks

```bash
rake manticore:setup                     # drop + create + populate all indexes

rake manticore:schema:create             # create tables
rake manticore:schema:drop               # drop tables
rake manticore:schema:rebuild            # drop + create

rake manticore:index:rebuild             # reindex all
rake manticore:index:rebuild[articles]   # reindex specific table
```

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

---

## Development

```bash
bundle install
bundle exec rspec              # all specs
bundle exec rspec spec/rails/  # Rails layer only
```

### Regenerating the HTTP client

```bash
openapi-generator-cli generate \
  -i https://raw.githubusercontent.com/manticoresoftware/openapi/master/manticore.yml \
  -g ruby -o ./ --skip-overwrite \
  --additional-properties=library=faraday,gemName=manticore/client,moduleName=ManticoreClient::Client,useAutoload=true
```

## Contributing

Contributions welcome. Open issues and pull requests against `main`.

## License

MIT. See [LICENSE.txt](LICENSE.txt).
