# Manticore::Client::SearchResponseHits

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **max_score** | **Integer** | Maximum score among the matched documents | [optional] |
| **total** | **Integer** | Total number of matched documents | [optional] |
| **total_relation** | **String** | Indicates whether the total number of hits is accurate or an estimate | [optional] |
| **hits** | [**Array&lt;HitsHits&gt;**](HitsHits.md) | Array of hit objects, each representing a matched document | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::SearchResponseHits.new(
  max_score: null,
  total: null,
  total_relation: null,
  hits: null
)
```

