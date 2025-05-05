# Manticore::Client::Aggregation

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **terms** | [**AggTerms**](AggTerms.md) |  | [optional] |
| **sort** | **Array&lt;Object&gt;** |  | [optional] |
| **composite** | [**AggComposite**](AggComposite.md) |  | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::Aggregation.new(
  terms: null,
  sort: null,
  composite: null
)
```

