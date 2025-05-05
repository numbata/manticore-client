# Manticore::Client::KnnQuery

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **field** | **String** | Field to perform the k-nearest neighbor search on |  |
| **k** | **Integer** | The number of nearest neighbors to return |  |
| **query_vector** | **Array&lt;Float&gt;** | The vector used as input for the KNN search | [optional] |
| **doc_id** | **Integer** | The docuemnt ID used as input for the KNN search | [optional] |
| **ef** | **Integer** | Optional parameter controlling the accuracy of the search | [optional] |
| **filter** | [**QueryFilter**](QueryFilter.md) |  | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::KnnQuery.new(
  field: null,
  k: null,
  query_vector: null,
  doc_id: null,
  ef: null,
  filter: null
)
```

