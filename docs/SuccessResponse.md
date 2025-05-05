# Manticore::Client::SuccessResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **table** | **String** | Name of the document table | [optional] |
| **id** | **Integer** | ID of the document affected by the request operation | [optional] |
| **created** | **Boolean** | Indicates whether the document was created as a result of the operation | [optional] |
| **result** | **String** | Result of the operation, typically &#39;created&#39;, &#39;updated&#39;, or &#39;deleted&#39; | [optional] |
| **found** | **Boolean** | Indicates whether the document was found in the table | [optional] |
| **status** | **Integer** | HTTP status code representing the result of the operation | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::SuccessResponse.new(
  table: null,
  id: null,
  created: null,
  result: null,
  found: null,
  status: null
)
```

