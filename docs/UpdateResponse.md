# Manticore::Client::UpdateResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **table** | **String** | Name of the document table | [optional] |
| **updated** | **Integer** | Number of documents updated | [optional] |
| **id** | **Integer** | Document ID | [optional] |
| **result** | **String** | Result of the update operation, typically &#39;updated&#39; | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::UpdateResponse.new(
  table: null,
  updated: null,
  id: null,
  result: null
)
```

