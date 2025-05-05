# Manticore::Client::Match

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **query** | **String** |  |  |
| **operator** | **String** |  | [optional] |
| **boost** | **Float** |  | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::Match.new(
  query: null,
  operator: null,
  boost: null
)
```

