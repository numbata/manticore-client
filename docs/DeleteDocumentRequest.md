# Manticore::Client::DeleteDocumentRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **table** | **String** | Table name |  |
| **cluster** | **String** | Cluster name | [optional] |
| **id** | **Integer** | The ID of document for deletion | [optional] |
| **query** | **Object** | Defines the criteria to match documents for deletion | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::DeleteDocumentRequest.new(
  table: null,
  cluster: null,
  id: null,
  query: null
)
```

