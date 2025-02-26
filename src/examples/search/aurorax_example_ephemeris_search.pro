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

pro aurorax_example_ephemeris_search
  ; ---------------------
  ; Introduction
  ; ---------------------
  ;
  ; The AuroraX conjunction search is underpinned by a large database of 'ephemeris' records. These records represent
  ; each minute that a ground instrument was operating, or a spacecraft was in orbit. Ephemeris records have location
  ; data in several formats (geodetic lat/lon, geomagnetic lat/lon, GSM coordinates), along with metadata that enables
  ; enhanced filtering.
  ;
  ; More information about ephemeris records in AuroraX can be found at https://docs.aurorax.space/about_the_data/overview/
  ; and https://docs.aurorax.space/about_the_data/categories/#ephemeris.
  ;
  ; A common stumbling block for making search queries is being unclear on the values that you can use for the program,
  ; platform, instrument type, etc. The AuroraX search engine is underpinned by 'data sources', and this is where the
  ; information can be found. Use the `aurorax_sources_list()` function to show all the available data sources that you can
  ; use when constructing search queries. For metadata filter requests, the information is also contained in the data sources
  ; that identify the available filter keys and values. We'll have a closer look at this in the metadata filter examples
  ; further below.
  ;
  ; Let's have a look at a basic search where we get ephemeris records for all times in a day for Swarm-A.
  aurorax_example_ephemeris_search1

  ; ---------------------
  ; Search with metadata filters
  ; ---------------------
  ; Using the metadata filters to help search for ephemeris records is one of the more advanced, and highly powerful,
  ; tools available. There are many metadata filters for spacecrafts, and some very useful ML-derived filters for
  ; ground-based all-sky imagers.
  ;
  ; An important part of being able to utilize the metadata filters is knowing the available keys and values. Each
  ; data source record has an attribute named `ephemeris_metadata_schema`. You can view this information by retrieving
  ; data sources (using the `aurorax_list_sources()` or `aurorax_get_source()` functions) and exploring their
  ; `ephemeris_metadata_filters` attributes.
  ;
  ; Let's look at a simple example where we search for ephemeris data filtering for when Swarm A was in the north polar
  ; cap. The regions available to choose from are all directly pulled from SSCWeb. Almost all data used by AuroraX for
  ; spacecrafts is from SSCWeb without any alterations, only organization in the AuroraX database to enable the search
  ; engine to function.
  ;
  ; If you're interested in interacting with the ML-derived metadata for ground-based instruments, have a look at the
  ; crib sheet at https://github.com/aurorax-space/idl-aurorax/blob/main/src/examples/search/aurorax_example_ephemeris_search_ml.pro
  aurorax_example_ephemeris_search2

  ; ---------------------
  ; Describe the ephemeris search as an SQL-like statement
  ; ---------------------
  ;
  ; To help understand the query a bit more, you can also 'describe' the search as an SQL-like statement. Let's look
  ; at a simple example of this.
  aurorax_example_ephemeris_search3

  ; ---------------------
  ; Configure the response data
  ; ---------------------
  ;
  ; Search data can be configured to only return certain pieces of information for each ephemeris record. For any web
  ; developers reading this guide, this is similar to GraphQL where you can easily control what data you get back from
  ; an API. The common use case for this is if you do a large ephemeris search (thousands of records), you can cut down
  ; on the amount of data that you get back. Perhaps you want to do a large search but only really care about the north
  ; B-Trace location and the epoch. You can use the response format parameter to prune down the result to be a fraction
  ; of the data that would normally be returned, effectively increasing the speed of data download / overall `search()`
  ; function time.
  ;
  ; To do this, we utilize the `response_format` parameter to control the ephemeris data structure we get back. One asterisks
  ; surrounding searches which use the response format parameter - the data returned will be hash, instead of a struct.
  ;
  ; The next question you may have is 'how do you know the response format possibilities'?
  ;
  ; To help answer this, you can use the `aurorax_create_response_format_template()` function. This will return a template
  ; for the `response_format` parameter. Take this, adjust as needed, and use for search requests.
  aurorax_example_ephemeris_search4
end

pro aurorax_example_ephemeris_search1
  ; a simple ephemeris search; get a day of Swarm A ephemeris records
  ;
  ; perform search
  print, '[Simple example] Starting search ...'
  response = aurorax_ephemeris_search( $
    '2019-01-01T00:00', $
    '2019-01-01T23:59', $
    programs = ['swarm'], $
    platforms = ['swarma'], $
    instrument_types = ['footprint'])
  print, '[Simple example] Found ' + string(n_elements(response.data), format = '(I0)') + ' ephemeris records'
  print, ''

  ; show output
  help, response
  print, ''

  help, response.data[0]
  print, ''
end

pro aurorax_example_ephemeris_search2
  ; get all ephemeris records in a day when Swarm A was in the north polar cap
  ;
  ; set search parameters
  start_ts = '2019-01-01T00:00'
  end_ts = '2019-01-01T23:59'
  programs = ['swarm']
  platforms = ['swarma']
  instrument_types = ['footprint']

  ; set metadata filter
  expressions = list(aurorax_create_metadata_filter_expression('nbtrace_region', 'north polar cap', /operator_eq))
  metadata_filters = aurorax_create_metadata_filter(expressions)

  ; perform search
  print, '[Simple metadata filters example] Starting search ...'
  r = aurorax_ephemeris_search(start_ts, $
    end_ts, $
    programs = programs, $
    platforms = platforms, $
    instrument_types = instrument_types, $
    metadata_filters = metadata_filters, $
    /quiet)
  print, '[Simple metadata filters example] Found ' + string(n_elements(r.data), format = '(I0)') + ' ephemeris records'
  print, ''
end

pro aurorax_example_ephemeris_search3
  ; set search parameters
  start_ts = '2019-01-01T00:00'
  end_ts = '2019-01-01T23:59'
  programs = ['swarm']
  platforms = ['swarma']
  instrument_types = ['footprint']

  ; describe it
  print, '[Describe example] Retrieving description ...'
  description = aurorax_ephemeris_describe(start_ts, end_ts, programs = programs, platforms = platforms, instrument_types = instrument_types)
  print, '[Describe example] Description: ' + description
  print, ''
end

pro aurorax_example_ephemeris_search4
  ; Do a simple ephemeris search for an hour of Swarm A data, with a specific response format. The response
  ; format will include the data source identifier, program, and platform. It will also include the geodetic
  ; location, the epoch, and any metadata.
  ;
  ; set our response format
  response_format = { $
    data_source: { $
      display_name: boolean(1), $
      identifier: boolean(1)}, $
    epoch: boolean(1), $
    nbtrace: { $
      lat: boolean(1), $
      lon: boolean(1)}, $
    sbtrace: { $
      lat: boolean(1), $
      lon: boolean(1)}, $
    metadata: boolean(1)}

  ; set core search parameters
  start_ts = '2019-01-01T00:00'
  end_ts = '2019-01-01T23:59'
  programs = ['swarm']
  platforms = ['swarma']
  instrument_types = ['footprint']

  ; perform search
  print, '[Response format example] Starting search ...'
  r = aurorax_ephemeris_search(start_ts, $
    end_ts, $
    programs = programs, $
    platforms = platforms, $
    instrument_types = instrument_types, $
    response_format = response_format, $
    /quiet)
  print, '[Response format example] Found ' + string(n_elements(r['data']), format = '(I0)') + ' ephemeris records'
  print, ''
end
