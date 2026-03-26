# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## manticore-rails

### [0.1.0] - Unreleased

#### Added
- ActiveRecord integration with ThinkingSphinx-style DSL (`define_manticore_index`)
- Full-text field indexing with association dot-notation support
- Typed attribute indexing (integer, datetime, boolean, float, string, text, json)
- Automatic `after_commit` callbacks for indexing and removal
- Association reindex callbacks via `reindex_on_change`
- Search with filters (`with:`, `without:`), sorting (`order:`), and pagination
- `search_for_ids` for lightweight ID-only queries
- Async indexing support via configurable job class
- Thread-safe `no_auto_indexing` block for bulk operations
- Rake tasks: `manticore:setup`, `manticore:schema:create/drop/rebuild`, `manticore:index:rebuild`
- Configurable index prefix, batch size, and error handling
- Custom serialization via `manticore_serialize` override
- SQL expression fields with `:as` aliases in schema DDL
- Table properties via `set_property` (e.g. `min_infix_len`, `morphology`)
- Circuit breaker to pause auto-indexing after consecutive failures (`circuit_breaker_threshold`)
- `ManticoreRails.reset_circuit!` for manual circuit breaker reset
- `on_error = :raise` mode for dev/test environments
- `ManticoreRails.healthy?` connection health check
- ActiveSupport::Notifications instrumentation (`search`, `bulk`, `delete` events)
- Rails generator: `rails g manticore:install`
- STI support in Registry (child classes inherit parent index)
- Association validation warnings at class load time
- Missing record detection and logging during `index_records`
- Frozen index definitions after registration to prevent mutation
- Date coercion in attribute serialization and search filters
- `Configuration#reset!` for test isolation
- Batch error isolation during `reindex_all`

## manticore-client

### [1.0.0] - Unreleased

#### Added
- Auto-generated Ruby client for ManticoreSearch HTTP API
- Index API: insert, replace, update, delete, bulk operations
- Search API: full-text search, filters, sorting, pagination
- Utils API: raw SQL execution
- Faraday-based HTTP transport
