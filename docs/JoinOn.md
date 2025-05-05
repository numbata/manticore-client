# Manticore::Client::JoinOn

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **right** | [**JoinCond**](JoinCond.md) |  | [optional] |
| **left** | [**JoinCond**](JoinCond.md) |  | [optional] |
| **operator** | **String** |  | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::JoinOn.new(
  right: null,
  left: null,
  operator: null
)
```

