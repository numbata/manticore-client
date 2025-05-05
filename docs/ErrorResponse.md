# Manticore::Client::ErrorResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **error** | [**ResponseError**](ResponseError.md) |  |  |
| **status** | **Integer** | HTTP status code of the error response | [optional][default to 500] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::ErrorResponse.new(
  error: null,
  status: null
)
```

