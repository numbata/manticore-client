# Manticore::Client::InsertDocumentRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **table** | **String** | Name of the table to insert the document into |  |
| **cluster** | **String** | Name of the cluster to insert the document into | [optional] |
| **id** | **Integer** | Document ID. If not provided, an ID will be auto-generated  | [optional] |
| **doc** | **Object** | Object containing document data  |  |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::InsertDocumentRequest.new(
  table: null,
  cluster: null,
  id: null,
  doc: null
)
```

