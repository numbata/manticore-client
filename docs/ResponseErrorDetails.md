# Manticore::Client::ResponseErrorDetails

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | **String** | Type or category of the error |  |
| **reason** | **String** | Detailed explanation of why the error occurred | [optional] |
| **table** | **String** | The table related to the error, if applicable | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::ResponseErrorDetails.new(
  type: null,
  reason: null,
  table: null
)
```

