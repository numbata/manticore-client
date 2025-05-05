# Manticore::Client::HitsHits

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **_id** | **Integer** | The ID of the matched document | [optional] |
| **_score** | **Integer** | The score of the matched document | [optional] |
| **_source** | **Object** | The source data of the matched document | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::HitsHits.new(
  _id: null,
  _score: null,
  _source: null
)
```

