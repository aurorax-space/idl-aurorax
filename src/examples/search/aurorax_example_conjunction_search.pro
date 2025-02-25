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

pro aurorax_example_conjunction_search
  ; ---------------------
  ; Introduction
  ; ---------------------
  ;
  ; The cornerstone aspect of the AuroraX search engine is the ability to automatically find
  ; conjunctions between ground-based instruments and spacecrafts. One aspect that makes AuroraX's
  ; conjunction search different from other solutions is that it will only find times where there
  ; is ground-based data available. It can also limit results to conjunctions where certain spacecraft
  ; instruments were operating. This integration with data availability saves us all valuable minutes
  ; and hours when surveying or searching for data that could be helpful for your next paper.
  ;
  ; A great way to get introduced to the AuroraX Conjunction Search capabilities is to head on over
  ; the web page (https://aurorax.space/conjunctionSearch/standard) and play around with UI there. Any
  ; request you can do in the web interface, you can also do using the below function.
  ;
  ; A common stumbling block for making search queries is being unclear on the values that you can use
  ; for the program, platform, instrument type, etc. The AuroraX search engine is underpinned by 'data sources',
  ; and this is where the information can be found. Use the `aurorax_list_sources()` function to show
  ; all the available data sources that you can use when constructing search queries. For metadata filter
  ; requests, the information is also contained in the data sources that identify the available filter keys
  ; and values. We'll have a closer look at this in the metadata filter examples in this crib sheet.
  aurorax_example_conjunction_search1

  ; --------------------
  ; Search for conjunctions with metadata filters
  ; --------------------
  ;
  ; Using the metadata filters to help search for conjunctions is one of the more advanced, and highly powerful,
  ; tools available. There are many metadata filters for spacecrafts, and some very useful ML-derived filters
  ; for ground-based all-sky imagers.
  ;
  ; An important part of being able to utilize the metadata filters is knowing the available keys and values. Each
  ; data source record has an attribute named `ephemeris_metadata_schema`. You can view this information by
  ; retrieving data sources (using the `aurorax_list_sources()` or `aurorax_get_source()` functions) and exploring
  ; their `ephemeris_metadata_filters` attributes. If you prefer to look at all the available metadata filters in
  ; a web browser instead, you can head on over to the AuroraX Conjunction Search webpage
  ; (https://aurorax.space/conjunctionSearch/standard). Select your data source(s), and click on the '+' icon for
  ; metadata filters, and a modal will pop up. All metadata filters for the selected data sources are displayed in
  ; the modal.
  ;
  ; Now that we understand the metadata filter keys and values a bit more, let's dive into some examples. We'll start
  ; with a simple example below, where we search for conjunctions filtering for when spacecrafts are in the north polar
  ; cap. The regions available to choose from are all directly pulled from SSCWeb. Almost all data used by AuroraX for
  ; spacecrafts is from SSCWeb without any alterations, only organization in the AuroraX database to enable the search
  ; engine to function.
  ;
  ; If you're interested in interacting with the ML-derived metadata for ground-based instruments, have a look at the
  ; crib sheet at https://github.com/aurorax-space/idl-aurorax/blob/main/src/examples/search/aurorax_example_ephemeris_search_ml.pro
  aurorax_example_conjunction_search2

  ; --------------------
  ; Multiple ground and space instruments, and advanced distances
  ; --------------------
  ;
  ; Since the `ground` and `space` parameters are lists, we can search for conjunctions between multiple ground and
  ; space instruments. Each item of the lists are evaluated as a logical AND statement when searching for conjunctions.
  ; In the web interface (https://aurorax.space/conjunctionSearch/standard), these are called 'criteria blocks' and
  ; are represented as each row in the table used for setting up a query. We do the same naming convention in IDL-AuroraX.
  ;
  ; You'll also notice that you can set distances between each list item (ground1-space1, ground1-space2, etc.). This
  ; can be quite powerful, but just remember to think about these values to ensure you're doing the right kind of
  ; distance evaluation between each. It can get confusing easily for each criteria block you add. A value of `None`
  ; will tell the search engine to not care about the distance between those two items.
  aurorax_example_conjunction_search3

  ; --------------------
  ; Search for conjunctions between spacecrafts only
  ; --------------------
  ;
  ; Since the conjunction search engine boils down to just finding matches between any two data sources, we can easily
  ; extend this to find conjunctions between only spacecrafts.
  aurorax_example_conjunction_search4

  ; --------------------
  ; Search for conjunctions with curated event lists
  ; --------------------
  ;
  ; There exist several curated event lists in the AuroraX search engine, including Toshi Nishimura's substorm
  ; list (DOI: https://doi.org/10.1002/2016JA022801), Megan Gillies' field line resonance list (DOI:
  ; https://doi.org/10.1007/s11214-021-00830-x), Bea Gallardo-Lacourt's STEVE list (DOI: https://doi.org/10.1029/2018JA025368),
  ; and Makenzie Ratzlaff's torches and omega band lists. To quickly look through these event lists, you can navigate
  ; to Swarm-Aurora (https://swarm-aurora.com/conjunctionFinder/) and use the 'custom import' dropdown to load the
  ; list you're interested in.
  ;
  ; We can use the AuroraX search engine to find conjunctions with any of these lists. Let's have a look at an example
  ; of using Toshi's substorm list to find conjunctions with any THEMIS spacecrafts.
  aurorax_example_conjunction_search5

  ; --------------------
  ; Search for conjunctions with custom locations
  ; --------------------
  ;
  ; We can also search for conjunctions with arbitrary geographic locations. Let's say you're planning to put an
  ; instrument somewhere and you want to see the conjunctions the new instrument will get with the Swarm spacecrafts.
  ; We can use the `custom_locations` parameter to perform the search.
  ;
  ; Let's have a look at an example of finding conjunctions between Calgary and any Swarm spacecraft over the course
  ; of a day.
  aurorax_example_conjunction_search6

  ; --------------------
  ; Adjusting the conjunction types parameter
  ; --------------------
  ;
  ; When performing conjunction searches, the parameter `conjunction_types` specifies the types of location data to
  ; use when finding conjunctions. The choices are: `nbtrace`, `sbtrace`, and `geographic`.
  ;
  ; If '/nbtrace' is used, then conjunctions will be found using the north B-field trace location data (northern magnetic
  ; footprints). If '/sbtrace' is used, then conjunctions will be found using the south B-field trace location data
  ; (southern magnetic footprints). And lastly, if '/geographic' is used, then conjunctions will be found using the
  ; geographic location data.
  ;
  ; Let's do two searches that show using the conjunction types paramter several different ways.
  aurorax_example_conjunction_search7
  aurorax_example_conjunction_search8

  ; --------------------
  ; Explore results in Swarm-Aurora
  ; --------------------
  ;
  ; Just like the web interface, you can also explore the results of a conjunction search in Swarm-Aurora. This is
  ; enabled by knowing the 'search request ID' value, and a handy helper function in IDL-AuroraX. The function will
  ; spawn a browser window and open up Swarm-Aurora, loading up the conjunction results that were found for that
  ; search request.
  aurorax_example_conjunction_search9

  ; --------------------
  ; Describe the conjunction search as an SQL-like statement
  ; --------------------
  ;
  ; To help understand the query a bit more, you can also 'describe' the search as an SQL-like statement. Let's
  ; look at a simple example of this.
  aurorax_example_conjunction_search10

  ; --------------------
  ; Configure the response data
  ; --------------------
  ;
  ; Search data can be configured to only return certain pieces of information for each conjunction record. For any
  ; web developers reading this guide, this is similar to GraphQL where you can easily control what data you get
  ; back from an API. The common use case for this is if you do a large conjunction search (thousands of results),
  ; you can cut down on the amount of data that you get back. Perhaps you want to do a large search but only really
  ; care about a few certain pieces of information about each conjunction. You can use the response format parameter
  ; to prune down the result to be a fraction of the data that would normally be returned, effectively increasing the
  ; speed of data download / overall `search()` function time.
  ;
  ; To do this, we utilize the `response_format` parameter to control the conjunction data structure we get back. One
  ; asterisks surrounding searches which use the response format parameter - the data returned will be a hash, instead
  ; of a struct.
  ;
  ; The next question you may have is 'how do you know the response format possibilities'?
  ;
  ; To help answer this, you can use the `aurorax_create_response_format_template()` function. This will return a template
  ; for the `response_format` parameter. Take this, adjust as needed, and use for search requests.
  aurorax_example_conjunction_search11
end

pro aurorax_example_conjunction_search1
  ; search for conjunctions between THEMIS ASI and Swarm
  ;
  ; define timeframe and distance parameters
  distance = 500
  start_dt = '2020-01-01T00:00:00'
  end_dt = '2020-01-01T06:59:59'

  ; create criteria blocks
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], /ground))
  space = list(aurorax_create_criteria_block(programs = ['swarm'], /space))

  ; perform search
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace)

  ; show data
  help, r
  print, ''
  help, r.data[0]
  print, ''
end

pro aurorax_example_conjunction_search2
  ; search for conjunctions between any THEMIS-ASI or REGO instrument, and any Swarm spacecraft where
  ; the north B-trace region is 'north polar cap'.
  ;
  ; NOTE: this region metadata is not derived by AuroraX, but instead directly from SSCWeb.
  ;
  ; set timeframe and distance
  distance = 500
  start_dt = '2019-02-01T00:00:00'
  end_dt = '2019-02-10T23:59:59'

  ; set ground criteria block
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi', 'rego'], /ground))

  ; set space criteria block, with a metadata filter
  expressions = list(aurorax_create_metadata_filter_expression('nbtrace_region', 'north polar cap', /operator_eq))
  metadata_filters = aurorax_create_metadata_filter(expressions)
  space = list(aurorax_create_criteria_block(programs = ['swarm'], metadata_filters = metadata_filters, /space))

  ; perform search
  print, '[Simple metadata filters example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Simple metadata filters example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_conjunction_search3
  ; Search for conjunctions between any REGO instrument, any TREx instrument,any Swarm spacecraft,
  ; and any THEMIS spacecraft, up to 500 km apart for each ground instrument and spacecraft. Since
  ; we have four list items, we can refer to this as a 'quadruple conjunction' search.
  ;
  ; set timeframe
  start_dt = '2020-01-01T00:00:00'
  end_dt = '2020-01-04T23:59:59'

  ; set criteria blocks
  ground = list( $
    aurorax_create_criteria_block(programs = ['rego'], /ground), $
    aurorax_create_criteria_block(programs = ['trex'], /ground))
  space = list( $
    aurorax_create_criteria_block(programs = ['swarm'], /space), $
    aurorax_create_criteria_block(programs = ['themis'], /space))

  ; set distances
  ;
  ; we are going to set the ground-to-ground and space-to-space distances as null, indicating
  ; to the search engine that we don't care about the distances between these pairings. To do
  ; this, we create an advanced distances hash, and edit it. You don't HAVE to do this, but for
  ; multi criteria blocks like this, most use cases utilize advanced distances in some way. If
  ; you don't need it, then you can simply set the distance to N (ie. 500) directly in the
  ; conjunction search call like previously done,  and it will set the distance for each pairing
  ; to that number.
  ;
  ; distances = {
  ; "ground1-ground2": null,
  ; "ground1-space1": 500,
  ; "ground1-space2": 500,
  ; "ground2-space1": 500,
  ; "ground2-space2": 500,
  ; "space1-space2": null
  ; }
  distances = aurorax_create_advanced_distances_hash(500, ground_count = n_elements(ground), space_count = n_elements(space))
  distances['ground1-ground2'] = !null
  distances['space1-space2'] = !null

  ; perform search
  print, '[Multiple criteria blocks example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distances, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Multiple criteria blocks example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_conjunction_search4
  ; search for conjunctions between Swarm A or Swarm B, and any THEMIS spacecraft with the south B-trace
  ; region matching 'south polar cap'
  ;
  ; set timeframe and distance
  start_dt = '2019-01-01T00:00:00'
  end_dt = '2019-01-01T23:59:59'
  distance = 500

  ; set first space criteria block
  space1 = aurorax_create_criteria_block(programs = ['themis'], /space)

  ; set second space criteria block, this one has a metadata filter applied to it
  expressions = list(aurorax_create_metadata_filter_expression('sbtrace_region', 'south polar cap', /operator_eq))
  metadata_filters = aurorax_create_metadata_filter(expressions)
  space2 = aurorax_create_criteria_block(programs = ['swarm'], $
    platforms = ['swarma', 'swarmb'], $
    hemisphere = ['southern'], $
    metadata_filters = metadata_filters, $
    /space)

  ; assemble space criteria block list
  space = list(space1, space2)

  ; perform search
  print, '[Space only example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, space = space, /nbtrace, /quiet)
  print, '[Space only example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_conjunction_search5
  ; Do a search between Toshi's substorm list and any THEMIS spacecraft over the year of
  ; 2008. We limit the year, since multi years will take a little longer to run than we'd
  ; like in a quick example like this is for. Feel free to do it though!
  ;
  ; set timeframe and distance
  start_dt = '2008-01-01T00:00:00'
  end_dt = '2008-12-31T23:59:59'
  distance = 500

  ; set criteria blocks
  space = list(aurorax_create_criteria_block(programs = ['themis'], /space))
  events = list(aurorax_create_criteria_block(instrument_types = ['substorm onset'], /events))

  ; perform search
  print, '[Events example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, space = space, events = events, /nbtrace, /quiet)
  print, '[Events example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_conjunction_search6
  ; find conjunctions between Calgary and any Swarm spacecraft over the course of a day
  ;
  ; set timeframe and distance
  distance = 500
  start_dt = '2018-01-01T00:00:00'
  end_dt = '2018-01-01T23:59:59'

  ; set criteria blocks
  space = list(aurorax_create_criteria_block(programs = ['swarm'], /space))
  custom = list(aurorax_create_criteria_block(locations = list([51.05, -114.07]), /custom))

  ; perform search
  print, '[Custom locations example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, space = space, custom = custom, /nbtrace, /quiet)
  print, '[Custom locations example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_conjunction_search7
  ; find conjunctions using both nbtrace and sbtrace for THEMIS-ASI and THEMIS spacecrafts
  ;
  ; set timeframe and distance
  start_dt = '2018-01-01T00:00:00'
  end_dt = '2018-01-01T23:59:59'
  distance = 400

  ; set criteria blocks
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], /ground))
  space = list(aurorax_create_criteria_block(programs = ['themis'], /space))

  ; perform search
  print, '[Conjunction types example 1] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /sbtrace, /quiet)
  print, '[Conjunction types example 1] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_conjunction_search8
  ; find conjunctions between an arbitrary location and any Swarm spacecraft's geographic location
  ;
  ; set timeframe and distance
  start_dt = '2018-01-01T00:00:00'
  end_dt = '2018-01-04T23:59:59'
  distance = 200

  ; set criteria blocks
  space = list(aurorax_create_criteria_block(programs = ['swarm'], /space))
  custom = list(aurorax_create_criteria_block(locations = list([51.04, -114.07]), /custom))

  ; perform search
  print, '[Conjunction types example 2] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, custom = custom, space = space, /geographic, /quiet)
  print, '[Conjunction types example 2] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_conjunction_search9
  ; do a search between a couple THEMIS ASIs and any Swarm spacecrafts
  ;
  ; set up parameters
  start_dt = '2019-01-01T00:00:00'
  end_dt = '2019-01-03T23:59:59'
  distance = 500
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], platforms = ['fort smith', 'gillam'], /ground))
  space = list(aurorax_create_criteria_block(programs = ['swarm'], hemisphere = ['northern'], /space))

  ; perform search
  print, '[Swarm-Aurora example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Swarm-Aurora example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'

  ; open in swarm-aurora
  print, '[Swarm-Aurora example] Spawning window with Swarm-Aurora in it ...'
  aurorax_open_conjunctions_in_swarmaurora, r.request_id
  print, ''
end

pro aurorax_example_conjunction_search10
  ; describe a search between a couple THEMIS ASIs and any Swarm spacecrafts
  ;
  ; set up parameters
  start_dt = '2019-01-01T00:00:00'
  end_dt = '2019-01-03T23:59:59'
  distance = 500
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], platforms = ['fort smith', 'gillam'], /ground))
  space = list(aurorax_create_criteria_block(programs = ['swarm'], hemisphere = ['northern'], /space))

  ; describe it
  print, '[Describe example] Retrieving description ...'
  description = aurorax_conjunction_describe(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace)
  print, '[Describe example] Description: ' + description
  print, ''
end

pro aurorax_example_conjunction_search11
  ; do a simple conjunction search for any THEMIS ASI and any Swarm spacecraft, over the
  ; span of 7 hours. The response format will include a minimal amount of information for
  ; each conjunction.

  ; set our response format
  response_format = { $
    start_ts: boolean(1), $
    end_ts: boolean(1), $
    farthest_epoch: boolean(1), $
    closest_epoch: boolean(1), $
    conjunction_type: boolean(1), $
    events: { $
      start_ts: boolean(1), $
      end_ts: boolean(1), $
      max_distance: boolean(1), $
      min_distance: boolean(1), $
      conjunction_type: boolean(1), $
      e1_source: { $
        display_name: boolean(1), $
        identifier: boolean(1)}, $
      e2_source: { $
        display_name: boolean(1), $
        identifier: boolean(1)}}, $
    data_sources: { $
      display_name: boolean(1), $
      identifier: boolean(1)}}

  ; set up parameters
  start_dt = '2020-01-01T00:00:00'
  end_dt = '2020-01-01T06:59:59'
  distance = 500
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], /ground))
  space = list(aurorax_create_criteria_block(programs = ['swarm'], /space))

  ; perform search
  print, '[Response format example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, $
    end_dt, $
    distance, $
    ground = ground, $
    space = space, $
    response_format = response_format, $
    /nbtrace, $
    /quiet)
  print, '[Response format example] Found ' + string(n_elements(r['data']), format = '(I0)') + ' conjunctions'
  print, ''
end
