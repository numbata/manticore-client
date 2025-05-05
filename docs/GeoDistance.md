# Manticore::Client::GeoDistance

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **location_anchor** | [**GeoDistanceLocationAnchor**](GeoDistanceLocationAnchor.md) |  | [optional] |
| **location_source** | **String** | Field name in the document that contains location data | [optional] |
| **distance_type** | **String** | Algorithm used to calculate the distance | [optional] |
| **distance** | **String** | The distance from the anchor point to filter results by | [optional] |

## Example

```ruby
require 'manticore/client'

instance = Manticore::Client::GeoDistance.new(
  location_anchor: null,
  location_source: null,
  distance_type: null,
  distance: null
)
```

