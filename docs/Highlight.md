# Manticore::Client::Highlight

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **fragment_size** | **Integer** | Maximum size of the text fragments in highlighted snippets per field | [optional] |
| **limit** | **Integer** | Maximum size of snippets per field | [optional] |
| **limit_snippets** | **Integer** | Maximum number of snippets per field | [optional] |
| **limit_words** | **Integer** | Maximum number of words per field | [optional] |
| **number_of_fragments** | **Integer** | Total number of highlighted fragments per field | [optional] |
| **after_match** | **String** | Text inserted after the matched term, typically used for HTML formatting | [optional][default to &#39;&lt;/strong&gt;&#39;] |
| **allow_empty** | **Boolean** | Permits an empty string to be returned as the highlighting result. Otherwise, the beginning of the original text would be returned | [optional] |
| **around** | **Integer** | Number of words around the match to include in the highlight | [optional] |
| **before_match** | **String** | Text inserted before the match, typically used for HTML formatting | [optional][default to &#39;&lt;strong&gt;&#39;] |
| **emit_zones** | **Boolean** | Emits an HTML tag with the enclosing zone name before each highlighted snippet | [optional] |
| **encoder** | **String** | If set to &#39;html&#39;, retains HTML markup when highlighting | [optional] |
| **fields** | [**HighlightAllOfFields**](HighlightAllOfFields.md) |  | [optional] |
| **force_all_words** | **Boolean** | Ignores the length limit until the result includes all keywords | [optional] |
| **force_snippets** | **Boolean** | Forces snippet generation even if limits allow highlighting the entire text | [optional] |
| **highlight_query** | [**QueryFilter**](QueryFilter.md) |  | [optional] |
| **html_strip_mode** | **String** | Defines the mode for handling HTML markup in the highlight | [optional] |
| **limits_per_field** | **Boolean** | Determines whether the &#39;limit&#39;, &#39;limit_words&#39;, and &#39;limit_snippets&#39; options operate as individual limits in each field of the document | [optional] |
| **no_match_size** | **Integer** | If set to 1, allows an empty string to be returned as a highlighting result | [optional] |
| **order** | **String** | Sets the sorting order of highlighted snippets | [optional] |
| **pre_tags** | **String** | Text inserted before each highlighted snippet | [optional][default to &#39;&lt;strong&gt;&#39;] |
| **post_tags** | **String** | Text inserted after each highlighted snippet | [optional][default to &#39;&lt;/strong&gt;&#39;] |
| **start_snippet_id** | **Integer** | Sets the starting value of the %SNIPPET_ID% macro | [optional] |
| **use_boundaries** | **Boolean** | Defines whether to additionally break snippets by phrase boundary characters | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::Highlight.new(
  fragment_size: null,
  limit: null,
  limit_snippets: null,
  limit_words: null,
  number_of_fragments: null,
  after_match: null,
  allow_empty: null,
  around: null,
  before_match: null,
  emit_zones: null,
  encoder: null,
  fields: null,
  force_all_words: null,
  force_snippets: null,
  highlight_query: null,
  html_strip_mode: null,
  limits_per_field: null,
  no_match_size: null,
  order: null,
  pre_tags: null,
  post_tags: null,
  start_snippet_id: null,
  use_boundaries: null
)
```

