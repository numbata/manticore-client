# Manticore::Client::UpdateDocumentRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **table** | **String** | Name of the document table |  |
| **cluster** | **String** | Name of the document cluster | [optional] |
| **doc** | **Object** | Object containing the document fields to update |  |
| **id** | **Integer** | Document ID | [optional] |
| **query** | [**QueryFilter**](QueryFilter.md) |  | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::UpdateDocumentRequest.new(
  table: null,
  cluster: null,
  doc: {gid&#x3D;10},
  id: null,
  query: null
)
```

