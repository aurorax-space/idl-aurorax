; -------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
; -------------------------------------------------------------

pro aurorax_example_data_products_search
  ; ---------------------
  ; Introduction
  ; ---------------------
  ; The AuroraX database also includes records describing data products for auroral data, such as keograms,
  ; montages, summary plots, etc. We can search for data products much we searching for ephemeris and conjunctions.
  ;
  ; More information about data product records can be found at https://docs.aurorax.space/about_the_data/overview/
  ; and https://docs.aurorax.space/about_the_data/categories/#data-products
  ;
  ; A common stumbling block for making search queries is being unclear on the values that you can use for the
  ; program, platform, instrument type, etc. The AuroraX search engine is underpinned by 'data sources', and
  ; this is where the information can be found. Use the `aurorax_sources_list()` function to show all the available
  ; data sources that you can use when constructing search queries. For metadata filter requests, the information
  ; is also contained in the data sources that identify the available filter keys and values. We'll have a closer
  ; look at this in the metadata filter examples further below.
  ;
  ; Let's have a look at a basic data product search. Let's get data product records for all TREx RGB instruments
  ; for a day.
  aurorax_example_data_products_search1

  ; ---------------------
  ; Search with metadata filters
  ; ---------------------
  ;
  ; Using the metadata filters to help search for data product records is one of the more advanced tools available.
  ; There exist metadata filters for some ground-based auroral data sources that we can utilize to filter our results
  ; further.
  ;
  ; An important part of being able to utilize the metadata filters is knowing the available keys and values. Each data
  ; source record has an attribute named `data_product_metadata_schema`. You can view this information by retrieving
  ; data sources (using the `aurorax_list_sources()` or `aurorax_get_source()` functions) and exploring their
  ; `data_product_metadata_schema` attributes.
  ;
  ; Let's look at a simple example where we search for data product data filtering for specifically daily keograms for
  ; the TREx RGBs.
  aurorax_example_data_products_search2

  ; ---------------------
  ; Describe the data products search as an SQL-like statement
  ; ---------------------
  ;
  ; To help understand the query a bit more, you can also 'describe' the search as an SQL-like statement. Let's look
  ; at a simple example of this.
  aurorax_example_data_products_search3

  ; ---------------------
  ; Configure the response data
  ; ---------------------
  ;
  ; Search data can be configured to only return certain pieces of information for each data product record. For any
  ; web developers reading this guide, this is similar to GraphQL where you can easily control what data you get back
  ; from an API. The common use case for this is if you do a data product search and you'd like to optimize the response
  ; time, you can cut down on the amount of data that you get back. Perhaps you want to do a search but only really care
  ; about a few certain key pieces of information. You can use the response format parameter to prune down the result to
  ; be a fraction of the data that would normally be returned, effectively increasing the speed of data download / overall
  ; `search()` function time.
  ;
  ; To do this, we utilize the `response_format` parameter to control the data product data structure we get back. One
  ; asterisks surrounding searches which use the response format parameter - the data returned will be a hash, instead of
  ; a struct.
  ;
  ; The next question you may have is 'how do you know the response format possibilities'?
  ;
  ; To help answer this, you can use the `aurorax_create_response_format_template()` function. This will return a template
  ; for the `response_format` parameter. Take this, adjust as needed, and use for search requests.
  aurorax_example_data_products_search4
end

pro aurorax_example_data_products_search1
  ; a simple search; get data product records for all TREx RGB instruments for a day
  ;
  ; perform search
  print, '[Simple example] Starting search ...'
  response = aurorax_data_product_search( $
    '2020-02-01T00:00', $
    '2020-02-01T23:59', $
    programs = ['trex'], $
    instrument_types = ['RGB ASI'])
  print, '[Simple example] Found ' + string(n_elements(response.data), format = '(I0)') + ' ephemeris records'
  print, ''

  ; show output
  help, response
  print, ''

  help, response.data[0]
  print, ''
end

pro aurorax_example_data_products_search2
  ; search for data product data filtering for specifically daily keograms for
  ; the TREx RGBs
  ;
  ; set search parameters
  start_ts = '2021-01-01T00:00'
  end_ts = '2021-01-01T23:59'
  programs = ['trex']
  instrument_types = ['RGB ASI']

  ; set metadata filters
  expressions = list(aurorax_create_metadata_filter_expression('keogram_type', 'daily', /operator_eq))
  metadata_filters = aurorax_create_metadata_filter(expressions)

  ; do search
  print, '[Metadata filter example] Starting search ...'
  r = aurorax_data_product_search( $
    start_ts, $
    end_ts, $
    programs = programs, $
    instrument_types = instrument_types, $
    metadata_filters = metadata_filters, $
    /quiet)
  print, '[Metadata filter example] Found ' + string(n_elements(r.data), format = '(I0)') + ' data product records'
  print, ''
end

pro aurorax_example_data_products_search3
  ; set search parameters
  start_ts = '2020-02-01T00:00'
  end_ts = '2020-02-01T23:59'
  programs = ['trex']
  instrument_types = ['RGB ASI']

  ; describe it
  print, '[Describe example] Retrieving description ...'
  description = aurorax_data_product_describe(start_ts, end_ts, programs = programs, instrument_types = instrument_types)
  print, '[Describe example] Description: ' + description
  print, ''
end

pro aurorax_example_data_products_search4
  ; Do a simple search for TREx RGB data products spanning a single day. The response format
  ; will include just the identifier and display name for the data source, and the start, end,
  ; and URL for the data product.
  ;
  ; set up response format
  response_format = { $
    start_ts: boolean(1), $
    end_ts: boolean(1), $
    url: boolean(1), $
    data_product_type: boolean(1), $
    data_source: { $
      display_name: boolean(1), $
      identifier: boolean(1)}}

  ; set core search parameters
  start_ts = '2020-02-01T00:00'
  end_ts = '2020-02-01T23:59'
  programs = ['trex']
  instrument_types = ['RGB ASI']

  ; do search
  print, '[Response format example] Starting search ...'
  r = aurorax_data_product_search( $
    start_ts, $
    end_ts, $
    programs = programs, $
    instrument_types = instrument_types, $
    response_format = response_format)
  print, '[Response format example] Found ' + string(n_elements(r['data']), format = '(I0)') + ' data product records'
  print, ''
end
