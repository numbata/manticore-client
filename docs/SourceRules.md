# Manticore::Client::SourceRules

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **includes** | **Array&lt;String&gt;** | List of fields to include in the response | [optional] |
| **excludes** | **Array&lt;String&gt;** | List of fields to exclude from the response | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::SourceRules.new(
  includes: null,
  excludes: null
)
```

