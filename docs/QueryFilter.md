# Manticore::Client::QueryFilter

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **query_string** | **String** | Filter object defining a query string | [optional] |
| **match** | **Object** | Filter object defining a match keyword passed as a string or in a Match object | [optional] |
| **match_phrase** | **Object** | Filter object defining a match phrase | [optional] |
| **match_all** | **Object** | Filter object to select all documents | [optional] |
| **bool** | [**BoolFilter**](BoolFilter.md) |  | [optional] |
| **equals** | **Object** |  | [optional] |
| **_in** | **Object** | Filter to match a given set of attribute values. | [optional] |
| **range** | **Object** | Filter to match a given range of attribute values passed in Range objects | [optional] |
| **geo_distance** | [**GeoDistance**](GeoDistance.md) |  | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::QueryFilter.new(
  query_string: null,
  match: null,
  match_phrase: null,
  match_all: null,
  bool: null,
  equals: null,
  _in: null,
  range: null,
  geo_distance: null
)
```

