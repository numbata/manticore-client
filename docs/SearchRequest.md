# Manticore::Client::SearchRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **table** | **String** | The table to perform the search on |  |
| **query** | [**SearchQuery**](SearchQuery.md) |  | [optional] |
| **join** | [**Array&lt;Join&gt;**](Join.md) | Join clause to combine search data from multiple tables | [optional] |
| **highlight** | [**Highlight**](Highlight.md) |  | [optional] |
| **limit** | **Integer** | Maximum number of results to return | [optional] |
| **knn** | [**KnnQuery**](KnnQuery.md) |  | [optional] |
| **aggs** | [**Hash&lt;String, Aggregation&gt;**](Aggregation.md) | Defines aggregation settings for grouping results | [optional] |
| **expressions** | **Hash&lt;String, String&gt;** | Expressions to calculate additional values for the result | [optional] |
| **max_matches** | **Integer** | Maximum number of matches allowed in the result | [optional] |
| **offset** | **Integer** | Starting point for pagination of the result | [optional] |
| **options** | **Object** | Additional search options | [optional] |
| **profile** | **Boolean** | Enable or disable profiling of the search request | [optional] |
| **sort** | **Object** |  | [optional] |
| **_source** | **Object** |  | [optional] |
| **track_scores** | **Boolean** | Enable or disable result weight calculation used for sorting | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::SearchRequest.new(
  table: null,
  query: null,
  join: null,
  highlight: null,
  limit: null,
  knn: null,
  aggs: {agg1&#x3D;{terms&#x3D;{field&#x3D;field1, size&#x3D;1000, sort&#x3D;[{field1&#x3D;null, order&#x3D;asc}]}}},
  expressions: {title_len&#x3D;crc32(title)},
  max_matches: null,
  offset: null,
  options: null,
  profile: null,
  sort: null,
  _source: null,
  track_scores: null
)
```

