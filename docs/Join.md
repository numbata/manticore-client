# Manticore::Client::Join

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | **String** | Type of the join operation |  |
| **on** | [**Array&lt;JoinOn&gt;**](JoinOn.md) | List of objects defining joined tables |  |
| **query** | [**FulltextFilter**](FulltextFilter.md) |  | [optional] |
| **table** | **String** | Basic table of the join operation |  |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::Join.new(
  type: null,
  on: null,
  query: null,
  table: null
)
```

