# Manticore::Client::HighlightFieldOption

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **fragment_size** | **Integer** | Maximum size of the text fragments in highlighted snippets per field | [optional] |
| **limit** | **Integer** | Maximum size of snippets per field | [optional] |
| **limit_snippets** | **Integer** | Maximum number of snippets per field | [optional] |
| **limit_words** | **Integer** | Maximum number of words per field | [optional] |
| **number_of_fragments** | **Integer** | Total number of highlighted fragments per field | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::HighlightFieldOption.new(
  fragment_size: null,
  limit: null,
  limit_snippets: null,
  limit_words: null,
  number_of_fragments: null
)
```

