# Manticore::Client::JoinCond

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **field** | **String** | Field to join on |  |
| **table** | **String** | Joined table |  |
| **type** | **Object** |  | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::JoinCond.new(
  field: null,
  table: null,
  type: null
)
```

