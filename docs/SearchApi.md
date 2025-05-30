# Manticore::Client::SearchApi

All URIs are relative to *http://127.0.0.1:9308*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**autocomplete**](SearchApi.md#autocomplete) | **POST** /autocomplete | Performs an autocomplete search on a table |
| [**percolate**](SearchApi.md#percolate) | **POST** /pq/{table}/search | Perform reverse search on a percolate table |
| [**search**](SearchApi.md#search) | **POST** /search | Performs a search on a table |


## autocomplete

> Array&lt;Object&gt; autocomplete(autocomplete_request)

Performs an autocomplete search on a table

 The method expects an object with the following mandatory properties: * the name of the table to search * the query string to autocomplete For details, see the documentation on [**Autocomplete**](Autocomplete.md) An example: ``` {   \"table\":\"table_name\",   \"query\":\"query_beginning\" }         ``` An example of the method's response:   ```  [    {      \"total\": 3,      \"error\": \"\",      \"warning\": \"\",      \"columns\": [        {          \"query\": {            \"type\": \"string\"          }        }      ],      \"data\": [        {          \"query\": \"hello\"        },        {          \"query\": \"helio\"        },        {          \"query\": \"hell\"        }      ]    }  ]   ```  For more detailed information about the autocomplete queries, please refer to the documentation [here](https://manual.manticoresearch.com/Searching/Autocomplete). 

### Examples

```ruby
require 'time'
require 'manticore/client'

api_instance = Manticore::Client::SearchApi.new
autocomplete_request = Manticore::Client::AutocompleteRequest.new({table: 'table_example', query: 'query_example'}) # AutocompleteRequest | 

begin
  # Performs an autocomplete search on a table
  result = api_instance.autocomplete(autocomplete_request)
  p result
rescue Manticore::Client::ApiError => e
  puts "Error when calling SearchApi->autocomplete: #{e}"
end
```

#### Using the autocomplete_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(Array&lt;Object&gt;, Integer, Hash)> autocomplete_with_http_info(autocomplete_request)

```ruby
begin
  # Performs an autocomplete search on a table
  data, status_code, headers = api_instance.autocomplete_with_http_info(autocomplete_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => Array&lt;Object&gt;
rescue Manticore::Client::ApiError => e
  puts "Error when calling SearchApi->autocomplete_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **autocomplete_request** | [**AutocompleteRequest**](AutocompleteRequest.md) |  |  |

### Return type

**Array&lt;Object&gt;**

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## percolate

> <SearchResponse> percolate(table, percolate_request)

Perform reverse search on a percolate table

Performs a percolate search. This method must be used only on percolate tables. Expects two parameters: the table name and an object with array of documents to be tested. An example of the documents object: ```   {     \"query\" {       \"percolate\": {         \"document\": {           \"content\":\"sample content\"         }       }     }   } ``` Responds with an object with matched stored queries:  ```   {     'timed_out':false,     'hits': {       'total':2,       'max_score':1,       'hits': [         {           'table':'idx_pq_1',           '_type':'doc',           '_id':'2',           '_score':'1',           '_source': {             'query': {               'match':{'title':'some'}             }           }         },         {           'table':'idx_pq_1',           '_type':'doc',           '_id':'5',           '_score':'1',           '_source': {             'query': {               'ql':'some | none'             }           }         }       ]     }   } ``` 

### Examples

```ruby
require 'time'
require 'manticore/client'

api_instance = Manticore::Client::SearchApi.new
table = 'table_example' # String | Name of the percolate table
percolate_request = Manticore::Client::PercolateRequest.new({query: Manticore::Client::PercolateRequestQuery.new({percolate: 3.56})}) # PercolateRequest | 

begin
  # Perform reverse search on a percolate table
  result = api_instance.percolate(table, percolate_request)
  p result
rescue Manticore::Client::ApiError => e
  puts "Error when calling SearchApi->percolate: #{e}"
end
```

#### Using the percolate_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SearchResponse>, Integer, Hash)> percolate_with_http_info(table, percolate_request)

```ruby
begin
  # Perform reverse search on a percolate table
  data, status_code, headers = api_instance.percolate_with_http_info(table, percolate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SearchResponse>
rescue Manticore::Client::ApiError => e
  puts "Error when calling SearchApi->percolate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **table** | **String** | Name of the percolate table |  |
| **percolate_request** | [**PercolateRequest**](PercolateRequest.md) |  |  |

### Return type

[**SearchResponse**](SearchResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## search

> <SearchResponse> search(search_request)

Performs a search on a table

 The method expects an object with the following mandatory properties: * the name of the table to search * the match query object For details, see the documentation on [**SearchRequest**](SearchRequest.md) The method returns an object with the following properties: - took: the time taken to execute the search query. - timed_out: a boolean indicating whether the query timed out. - hits: an object with the following properties:    - total: the total number of hits found.    - hits: an array of hit objects, where each hit object represents a matched document. Each hit object has the following properties:      - _id: the ID of the matched document.      - _score: the score of the matched document.      - _source: the source data of the matched document.  In addition, if profiling is enabled, the response will include an additional array with profiling information attached. Also, if pagination is enabled, the response will include an additional 'scroll' property with a scroll token to use for pagination Here is an example search response:    ```   {     'took':10,     'timed_out':false,     'hits':     {       'total':2,       'hits':       [         {'_id':'1','_score':1,'_source':{'gid':11}},         {'_id':'2','_score':1,'_source':{'gid':12}}       ]     }   }   ```  For more information about the match query syntax and additional parameters that can be added to request and response, please see the documentation [here](https://manual.manticoresearch.com/Searching/Full_text_matching/Basic_usage#HTTP-JSON). 

### Examples

```ruby
require 'time'
require 'manticore/client'

api_instance = Manticore::Client::SearchApi.new
search_request = Manticore::Client::SearchRequest.new({table: 'table_example'}) # SearchRequest | 

begin
  # Performs a search on a table
  result = api_instance.search(search_request)
  p result
rescue Manticore::Client::ApiError => e
  puts "Error when calling SearchApi->search: #{e}"
end
```

#### Using the search_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SearchResponse>, Integer, Hash)> search_with_http_info(search_request)

```ruby
begin
  # Performs a search on a table
  data, status_code, headers = api_instance.search_with_http_info(search_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SearchResponse>
rescue Manticore::Client::ApiError => e
  puts "Error when calling SearchApi->search_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **search_request** | [**SearchRequest**](SearchRequest.md) |  |  |

### Return type

[**SearchResponse**](SearchResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

