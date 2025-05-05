# Manticore::Client::AggComposite

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **size** | **Integer** | Maximum number of composite buckets in the result | [optional] |
| **sources** | **Array&lt;Hash&lt;String, AggCompositeSource&gt;&gt;** |  | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::AggComposite.new(
  size: 1000,
  sources: null
)
```

