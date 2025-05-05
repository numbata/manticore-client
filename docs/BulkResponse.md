# Manticore::Client::BulkResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **items** | **Array&lt;Object&gt;** | List of results | [optional] |
| **errors** | **Boolean** | Errors occurred during the bulk operation | [optional] |
| **error** | **String** | Error message describing an error if such occurred | [optional] |
| **current_line** | **Integer** | Number of the row returned in the response | [optional] |
| **skipped_lines** | **Integer** | Number of rows skipped in the response | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::BulkResponse.new(
  items: null,
  errors: null,
  error: null,
  current_line: null,
  skipped_lines: null
)
```

