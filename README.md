# manticore-client

![RubyGems Version](https://img.shields.io/gem/v/manticore-client)
![CI Status](https://github.com/numbata/manticoresearch-ruby/actions/workflows/ci.yml/badge.svg)

A Ruby client for [Manticore Search](https://manticoresearch.com), generated from the OpenAPI specification.

**API Version:** 5.0.0  •  **Gem Version:** 1.0.0  •  **Generator:** OpenAPI Generator v7.13.0

---

## Table of Contents

* [Installation](#installation)
* [Usage](#usage)
* [Configuration](#configuration)
* [Documentation](#documentation)
* [Development](#development)
* [Contributing](#contributing)
* [License](#license)

---

## Installation

### From RubyGems

Add to your `Gemfile`:

```ruby
gem 'manticore-client', '~> 1.0'
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install manticore-client
```

### From GitHub

```ruby
# Gemfile
gem 'manticore-client', git: 'https://github.com/numbata/manticore-client.git'
```

## Usage

```ruby
require 'manticore-client'

# Optionally configure credentials or host
Manticore::Client.configure do |config|
  config.host = 'http://127.0.0.1:9308'
  config.username = 'user'
  config.password = 'pass'
end

# Create an API client instance
client = Manticore::Client::IndexApi.new

# Example: bulk operations
body = { /* your bulk payload */ }
begin
  response = client.bulk(body)
  puts response
rescue Manticore::Client::ApiError => e
  warn "API error: #{e.message} (status=#{e.code})"
end
```

## Configuration

You can override default settings by calling `configure`. Available options:

| Option     | Default                 | Description                           |
| ---------- | ----------------------- | ------------------------------------- |
| `host`     | `http://127.0.0.1:9308` | Base URL for the Manticore Search API |
| `username` | *nil*                   | HTTP Basic auth username              |
| `password` | *nil*                   | HTTP Basic auth password              |
| `timeout`  | `60`                    | HTTP request timeout in seconds       |

## Documentation

Generated API and model documentation is available under the `docs/` directory:

* [API Endpoints](docs/IndexApi.md)
* [Model Reference](docs/AggComposite.md)

Or browse online at [GitHub Pages](https://numbata.github.io/manticore-client).

## Development

1. Fork and clone this repository
2. Install dependencies:

   ```bash
   bundle install
   ```
3. Run tests:

   ```bash
   bundle exec rspec
   ```
4. Regenerate client after schema changes:

   ```bash
   openapi-generator-cli generate \
     -i https://raw.githubusercontent.com/manticoresoftware/openapi/master/manticore.yml \
     -g ruby \
     -o ./ \
     --skip-overwrite \
     --additional-properties=\
       library=faraday,\
       gemName=manticore/client,\
       moduleName=Manticore::Client,\
       useAutoload=true
   ```

## Contributing

Contributions are welcome! Please open issues and pull requests against `main`. Ensure your code passes lint and tests before submitting.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
