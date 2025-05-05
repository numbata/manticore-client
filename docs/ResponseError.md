# Manticore::Client::ResponseError

## Class instance methods

### `openapi_one_of`

Returns the list of classes defined in oneOf.

#### Example

```ruby
require 'manticore/client'

Manticore::Client::ResponseError.openapi_one_of
# =>
# [
#   :'ResponseErrorDetails',
#   :'String'
# ]
```

### build

Find the appropriate object from the `openapi_one_of` list and casts the data into it.

#### Example

```ruby
require 'manticore/client'

Manticore::Client::ResponseError.build(data)
# => #<ResponseErrorDetails:0x00007fdd4aab02a0>

Manticore::Client::ResponseError.build(data_that_doesnt_match)
# => nil
```

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| **data** | **Mixed** | data to be matched against the list of oneOf items |

#### Return type

- `ResponseErrorDetails`
- `String`
- `nil` (if no type matches)

