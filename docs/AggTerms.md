# Manticore::Client::AggTerms

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **field** | **String** | Name of attribute to aggregate by |  |
| **size** | **Integer** | Maximum number of buckets in the result | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::AggTerms.new(
  field: field1,
  size: 1000
)
```

