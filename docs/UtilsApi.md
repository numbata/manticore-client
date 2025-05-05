# Manticore::Client::UtilsApi

All URIs are relative to *http://127.0.0.1:9308*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**sql**](UtilsApi.md#sql) | **POST** /sql | Perform SQL requests |


## sql

> <SqlResponse> sql(body, opts)

Perform SQL requests

Run a query in SQL format. Expects a query string passed through `body` parameter and optional `raw_response` parameter that defines a format of response. `raw_response` can be set to `False` for Select queries only, e.g., `SELECT * FROM mytable` The query string must stay as it is, no URL encoding is needed. The response object depends on the query executed. In select mode the response has same format as `/search` operation. 

### Examples

```ruby
require 'time'
require 'manticore/client'

api_instance = Manticore::Client::UtilsApi.new
body = 'SHOW TABLES' # String | A query parameter string. 
opts = {
  raw_response: true # Boolean | Optional parameter, defines a format of response. Can be set to `False` for Select only queries and set to `True` for any type of queries. Default value is 'True'. 
}

begin
  # Perform SQL requests
  result = api_instance.sql(body, opts)
  p result
rescue Manticore::Client::ApiError => e
  puts "Error when calling UtilsApi->sql: #{e}"
end
```

#### Using the sql_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SqlResponse>, Integer, Hash)> sql_with_http_info(body, opts)

```ruby
begin
  # Perform SQL requests
  data, status_code, headers = api_instance.sql_with_http_info(body, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SqlResponse>
rescue Manticore::Client::ApiError => e
  puts "Error when calling UtilsApi->sql_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **body** | **String** | A query parameter string.  |  |
| **raw_response** | **Boolean** | Optional parameter, defines a format of response. Can be set to &#x60;False&#x60; for Select only queries and set to &#x60;True&#x60; for any type of queries. Default value is &#39;True&#39;.  | [optional][default to true] |

### Return type

[**SqlResponse**](SqlResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: text/plain
- **Accept**: application/json

