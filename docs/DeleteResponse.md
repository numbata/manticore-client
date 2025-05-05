# Manticore::Client::DeleteResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **table** | **String** | The name of the table from which the document was deleted | [optional] |
| **deleted** | **Integer** | Number of documents deleted | [optional] |
| **id** | **Integer** | The ID of the deleted document. If multiple documents are deleted, the ID of the first deleted document is returned | [optional] |
| **found** | **Boolean** | Indicates whether any documents to be deleted were found | [optional] |
| **result** | **String** | Result of the delete operation, typically &#39;deleted&#39; | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::DeleteResponse.new(
  table: null,
  deleted: null,
  id: null,
  found: null,
  result: null
)
```

