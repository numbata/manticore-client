# Manticore::Client::IndexApi

All URIs are relative to *http://127.0.0.1:9308*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**bulk**](IndexApi.md#bulk) | **POST** /bulk | Bulk table operations |
| [**delete**](IndexApi.md#delete) | **POST** /delete | Delete a document in a table |
| [**insert**](IndexApi.md#insert) | **POST** /insert | Create a new document in a table |
| [**partial_replace**](IndexApi.md#partial_replace) | **POST** /{table}/_update/{id} | Partially replaces a document in a table |
| [**replace**](IndexApi.md#replace) | **POST** /replace | Replace new document in a table |
| [**update**](IndexApi.md#update) | **POST** /update | Update a document in a table |


## bulk

> <BulkResponse> bulk(body)

Bulk table operations

Sends multiple operatons like inserts, updates, replaces or deletes.  For each operation it's object must have same format as in their dedicated method.  The method expects a raw string as the batch in NDJSON.  Each operation object needs to be serialized to   JSON and separated by endline (\\n).      An example of raw input:      ```   {\"insert\": {\"table\": \"movies\", \"doc\": {\"plot\": \"A secret team goes to North Pole\", \"rating\": 9.5, \"language\": [2, 3], \"title\": \"This is an older movie\", \"lon\": 51.99, \"meta\": {\"keywords\":[\"travel\",\"ice\"],\"genre\":[\"adventure\"]}, \"year\": 1950, \"lat\": 60.4, \"advise\": \"PG-13\"}}}   \\n   {\"delete\": {\"table\": \"movies\",\"id\":700}}   ```      Responds with an object telling whenever any errors occured and an array with status for each operation:      ```   {     'items':     [       {         'update':{'table':'products','id':1,'result':'updated'}       },       {         'update':{'table':'products','id':2,'result':'updated'}       }     ],     'errors':false   }   ``` 

### Examples

```ruby
require 'time'
require 'manticore/client'

api_instance = Manticore::Client::IndexApi.new
body = 'body_example' # String | 

begin
  # Bulk table operations
  result = api_instance.bulk(body)
  p result
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->bulk: #{e}"
end
```

#### Using the bulk_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<BulkResponse>, Integer, Hash)> bulk_with_http_info(body)

```ruby
begin
  # Bulk table operations
  data, status_code, headers = api_instance.bulk_with_http_info(body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <BulkResponse>
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->bulk_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **body** | **String** |  |  |

### Return type

[**BulkResponse**](BulkResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/x-ndjson
- **Accept**: application/json


## delete

> <DeleteResponse> delete(delete_document_request)

Delete a document in a table

Delete one or several documents. The method has 2 ways of deleting: either by id, in case only one document is deleted or by using a  match query, in which case multiple documents can be delete . Example of input to delete by id:    ```   {'table':'movies','id':100}   ```  Example of input to delete using a query:    ```   {     'table':'movies',     'query':     {       'bool':       {         'must':         [           {'query_string':'new movie'}         ]       }     }   }   ```  The match query has same syntax as in for searching. Responds with an object telling how many documents got deleted:     ```   {'table':'products','updated':1}   ``` 

### Examples

```ruby
require 'time'
require 'manticore/client'

api_instance = Manticore::Client::IndexApi.new
delete_document_request = Manticore::Client::DeleteDocumentRequest.new({table: 'table_example'}) # DeleteDocumentRequest | 

begin
  # Delete a document in a table
  result = api_instance.delete(delete_document_request)
  p result
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->delete: #{e}"
end
```

#### Using the delete_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<DeleteResponse>, Integer, Hash)> delete_with_http_info(delete_document_request)

```ruby
begin
  # Delete a document in a table
  data, status_code, headers = api_instance.delete_with_http_info(delete_document_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <DeleteResponse>
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->delete_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **delete_document_request** | [**DeleteDocumentRequest**](DeleteDocumentRequest.md) |  |  |

### Return type

[**DeleteResponse**](DeleteResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## insert

> <SuccessResponse> insert(insert_document_request)

Create a new document in a table

Insert a document.  Expects an object like:     ```   {     'table':'movies',     'id':701,     'doc':     {       'title':'This is an old movie',       'plot':'A secret team goes to North Pole',       'year':1950,       'rating':9.5,       'lat':60.4,       'lon':51.99,       'advise':'PG-13',       'meta':'{\"keywords\":{\"travel\",\"ice\"},\"genre\":{\"adventure\"}}',       'language':[2,3]     }   }   ```   The document id can also be missing, in which case an autogenerated one will be used:             ```   {     'table':'movies',     'doc':     {       'title':'This is a new movie',       'plot':'A secret team goes to North Pole',       'year':2020,       'rating':9.5,       'lat':60.4,       'lon':51.99,       'advise':'PG-13',       'meta':'{\"keywords\":{\"travel\",\"ice\"},\"genre\":{\"adventure\"}}',       'language':[2,3]     }   }   ```   It responds with an object in format:      ```   {'table':'products','id':701,'created':true,'result':'created','status':201}   ``` 

### Examples

```ruby
require 'time'
require 'manticore/client'

api_instance = Manticore::Client::IndexApi.new
insert_document_request = Manticore::Client::InsertDocumentRequest.new({table: 'table_example', doc: 3.56}) # InsertDocumentRequest | 

begin
  # Create a new document in a table
  result = api_instance.insert(insert_document_request)
  p result
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->insert: #{e}"
end
```

#### Using the insert_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SuccessResponse>, Integer, Hash)> insert_with_http_info(insert_document_request)

```ruby
begin
  # Create a new document in a table
  data, status_code, headers = api_instance.insert_with_http_info(insert_document_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SuccessResponse>
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->insert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **insert_document_request** | [**InsertDocumentRequest**](InsertDocumentRequest.md) |  |  |

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## partial_replace

> <UpdateResponse> partial_replace(table, id, replace_document_request)

Partially replaces a document in a table

Partially replaces a document with given id in a table Responds with an object of the following format:     ```   {'table':'products','updated':1}   ``` 

### Examples

```ruby
require 'time'
require 'manticore/client'

api_instance = Manticore::Client::IndexApi.new
table = 'table_example' # String | Name of the percolate table
id = 789 # Integer | Id of the document to replace
replace_document_request = Manticore::Client::ReplaceDocumentRequest.new({doc: 3.56}) # ReplaceDocumentRequest | 

begin
  # Partially replaces a document in a table
  result = api_instance.partial_replace(table, id, replace_document_request)
  p result
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->partial_replace: #{e}"
end
```

#### Using the partial_replace_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UpdateResponse>, Integer, Hash)> partial_replace_with_http_info(table, id, replace_document_request)

```ruby
begin
  # Partially replaces a document in a table
  data, status_code, headers = api_instance.partial_replace_with_http_info(table, id, replace_document_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UpdateResponse>
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->partial_replace_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **table** | **String** | Name of the percolate table |  |
| **id** | **Integer** | Id of the document to replace |  |
| **replace_document_request** | [**ReplaceDocumentRequest**](ReplaceDocumentRequest.md) |  |  |

### Return type

[**UpdateResponse**](UpdateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## replace

> <SuccessResponse> replace(insert_document_request)

Replace new document in a table

Replace an existing document. Input has same format as `insert` operation. Responds with an object in format:    ```   {'table':'products','id':1,'created':false,'result':'updated','status':200}   ``` 

### Examples

```ruby
require 'time'
require 'manticore/client'

api_instance = Manticore::Client::IndexApi.new
insert_document_request = Manticore::Client::InsertDocumentRequest.new({table: 'table_example', doc: 3.56}) # InsertDocumentRequest | 

begin
  # Replace new document in a table
  result = api_instance.replace(insert_document_request)
  p result
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->replace: #{e}"
end
```

#### Using the replace_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SuccessResponse>, Integer, Hash)> replace_with_http_info(insert_document_request)

```ruby
begin
  # Replace new document in a table
  data, status_code, headers = api_instance.replace_with_http_info(insert_document_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SuccessResponse>
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->replace_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **insert_document_request** | [**InsertDocumentRequest**](InsertDocumentRequest.md) |  |  |

### Return type

[**SuccessResponse**](SuccessResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## update

> <UpdateResponse> update(update_document_request)

Update a document in a table

Update one or several documents. The update can be made by passing the id or by using a match query in case multiple documents can be updated.  For example update a document using document id:    ```   {'table':'movies','doc':{'rating':9.49},'id':100}   ```  And update by using a match query:    ```   {     'table':'movies',     'doc':{'rating':9.49},     'query':     {       'bool':       {         'must':         [           {'query_string':'new movie'}         ]       }     }   }   ```   The match query has same syntax as for searching. Responds with an object that tells how many documents where updated in format:     ```   {'table':'products','updated':1}   ``` 

### Examples

```ruby
require 'time'
require 'manticore/client'

api_instance = Manticore::Client::IndexApi.new
update_document_request = Manticore::Client::UpdateDocumentRequest.new({table: 'table_example', doc: {gid=10}}) # UpdateDocumentRequest | 

begin
  # Update a document in a table
  result = api_instance.update(update_document_request)
  p result
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->update: #{e}"
end
```

#### Using the update_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UpdateResponse>, Integer, Hash)> update_with_http_info(update_document_request)

```ruby
begin
  # Update a document in a table
  data, status_code, headers = api_instance.update_with_http_info(update_document_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UpdateResponse>
rescue Manticore::Client::ApiError => e
  puts "Error when calling IndexApi->update_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **update_document_request** | [**UpdateDocumentRequest**](UpdateDocumentRequest.md) |  |  |

### Return type

[**UpdateResponse**](UpdateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

