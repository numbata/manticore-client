# Manticore::Client::FulltextFilter

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **query_string** | **String** | Filter object defining a query string | [optional] |
| **match** | **Object** | Filter object defining a match keyword passed as a string or in a Match object | [optional] |
| **match_phrase** | **Object** | Filter object defining a match phrase | [optional] |
| **match_all** | **Object** | Filter object to select all documents | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::FulltextFilter.new(
  query_string: null,
  match: null,
  match_phrase: null,
  match_all: null
)
```

