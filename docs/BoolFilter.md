# Manticore::Client::BoolFilter

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **must** | [**Array&lt;QueryFilter&gt;**](QueryFilter.md) | Query clauses that must match for the document to be included | [optional] |
| **must_not** | [**Array&lt;QueryFilter&gt;**](QueryFilter.md) | Query clauses that must not match for the document to be included | [optional] |
| **should** | [**Array&lt;QueryFilter&gt;**](QueryFilter.md) | Query clauses that should be matched, but are not required | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::BoolFilter.new(
  must: null,
  must_not: null,
  should: null
)
```

