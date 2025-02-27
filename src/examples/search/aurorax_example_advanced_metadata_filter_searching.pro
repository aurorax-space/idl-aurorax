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

pro aurorax_example_advanced_metadata_filter_searching
  ; ---------------------
  ; Introduction
  ; ---------------------
  ;
  ; When interacting wit the AuroraX search engine, you can utilize metadata filtering capabilities to
  ; further hone your searches. In other example notebooks, we've seen already a few examples of this,
  ; such as limiting results when spacecrafts are in certain regions or when an ML model believes an ASI
  ; is not cloudy. In this example notebook, we'll explore a full range of metadata filter options available
  ; to you when constructing search requests.
  ;
  ; First up, a reminder. An important part of being able to utilize the metadata filters in the AuroraX
  ; search engine is knowing the available keys and values. Each data source record has an attribute named
  ; `ephemeris_metadata_schema` and `data_products_metadata_schema`. The 'ephemeris' schema is used for
  ; conjunction and ephemeris searching, and the 'data products' schema is used for data product searching.
  ;
  ; Let's start with a conjunction search using a simple metadata filter.
  aurorax_example_advanced_metadata_filter_searching1

  ; ---------------------
  ; Single expression, multiple values
  ; ---------------------
  ; You'll notice in the above example that we have set the metadata filter to be only one expression - if
  ; the spacecraft north B-field magnetic footprint is in the north polar cap. Let's adjust this example to
  ; still have only one expression, but make it so that the nbtrace_region can be multiple values.
  aurorax_example_advanced_metadata_filter_searching2

  ; ---------------------
  ; Multiple expressions
  ; ---------------------
  ;
  ; Let's build off the above example to look at doing searches with multiple expressions. As mentioned above,
  ; when doing an expression with multiple values, the search engine evaluates each value using a logical OR.
  ; What if we wanted it to evaluate using a logical AND?
  ;
  ; We can achieve this using two expressions, each with a single value. The default operator for a metadata
  ; filter (not the expression) is 'AND'.
  ;
  ; Let's adjust the above example to see how to do this.
  aurorax_example_advanced_metadata_filter_searching3

  ; ---------------------
  ; Exploring numerical expression values and operators
  ; ---------------------
  ;
  ; For some metadata filter keys, the values are a numerical number. For example, the values for the
  ; `calgary_cloud_ml_v1` key are a string/list-of-strings, but the `calgary_cloud_ml_v1_confidence` key is a
  ; number between 0 and 100. To integrate these numerical keys into our expressions, we have a few different
  ; operators at our disposal: `=`, `!=`, `>`, `<`, `>=`, `<=`, and `between`.

  ; Let's have a look at a simple example using the `>=` operator. We're going to find conjunctions with Swarm
  ; where the UCalgary cloud ML model thinks any THEMIS ASI data is not cloudy and that classification has
  ; a confidence of >= 75%.
  aurorax_example_advanced_metadata_filter_searching4

  ; ---------------------
  ; Using the `between` operator
  ; ---------------------
  ;
  ; The `between` operator is a special case, different from the rest when constructing an expression. This
  ; is because this operator requires that the values be a list, and only contain two elements.
  ;
  ; Let's have a look at an example similar to the one directly above. Instead of finding conjunctions where
  ; the ML model thinks the confidence is above a certain number, let's adjust that to be a confidence between
  ; two numbers.
  aurorax_example_advanced_metadata_filter_searching5

  ; ---------------------
  ; Ephemeris searching with metadata filters
  ; ---------------------
  ;
  ; When doing ephemeris searches instead of conjunction searches like we have been in this notebook, there
  ; is no difference with the `metadata_filters` parameter. All queries share the same way of doing metadata
  ; filters, so you can easily port over the above examples to retrieve ephemeris records.
  ;
  ; For more examples, you can check out the ephemeris searching examples, and the ML-enhanced conjunction
  ; and ephemeris searching examples.

  ; ---------------------

  ; Data product searching with metadata filters
  ; ---------------------
  ;
  ; When doing data product searches, again there is no difference with the `metadata_filters` parameter.
  ; The only difference is the keys and values for data product metadata filtering will be different than
  ; the ones used in conjunction or ephemeris searches. The underlying data is different, and therefore has
  ; different filters that are available.
  ;
  ; For more examples, you can check out the data product searching examples.
end

pro aurorax_example_advanced_metadata_filter_searching1
  ; Search for conjunctions between any THEMIS-ASI instrument, and any Swarm
  ; spacecraft where the north B-trace region is 'north polar cap'.
  ;
  ; NOTE: this region metadata is not derived by AuroraX, but instead by SSCWeb.
  ; This is the same for several other metadata fields for spacecrafts.
  ;
  ; set timeframe and distance
  start_dt = '2019-02-01T00:00:00'
  end_dt = '2019-02-10T23:59:59'
  distance = 500

  ; set ground criteria block
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], /ground))

  ; set space criteria block, with a metadata filter
  expressions = list(aurorax_create_metadata_filter_expression('nbtrace_region', 'north polar cap', /operator_eq))
  metadata_filters = aurorax_create_metadata_filter(expressions)
  space = list(aurorax_create_criteria_block(programs = ['swarm'], metadata_filters = metadata_filters, /space))

  ; perform search
  print, '[Simple example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Simple example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_advanced_metadata_filter_searching2
  ; do a search with metadata filters being a single expression, with multiple
  ; possible values
  ;
  ; set timeframe and distance
  start_dt = '2019-02-01T00:00:00'
  end_dt = '2019-02-10T23:59:59'
  distance = 500

  ; set ground criteria block
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], /ground))

  ; set space criteria block, with a metadata filter
  expressions = list(aurorax_create_metadata_filter_expression('nbtrace_region', ['north polar cap', 'north auroral oval'], /operator_in))
  metadata_filters = aurorax_create_metadata_filter(expressions)
  space = list(aurorax_create_criteria_block(programs = ['swarm'], metadata_filters = metadata_filters, /space))

  ; perform search
  print, '[Single expression multiple values example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Single expression multiple values example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''

  ; Notice that the `values` parameter turned into a list, and the `operator` became 'in'. This
  ; is how we set an expression for multiple values. Each value is evaluated in the search engine
  ; as a logical OR; so this would find results where any Swarm spacecraft was either in the north
  ; polar cap OR in the north auroral oval.
  ;
  ; If we were to think back to the first example of an expression with a single value, the following
  ; way to write it would yield the same results.
  ;
  ; Method 1: `expression1 = aurorax_create_metadata_filter_expression('nbtrace_region', 'north polar cap', operator="=")`
  ;
  ; Method 2: `expression1 = aurorax_create_metadata_filter_expression('nbtrace_region', ['north polar cap"], operator="in")`
end

pro aurorax_example_advanced_metadata_filter_searching3
  ; do a search with metadata filters having multiple expressions
  ;
  ; set timeframe and distance
  start_dt = '2019-02-01T00:00:00'
  end_dt = '2019-02-10T23:59:59'
  distance = 500

  ; set ground criteria block
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], /ground))

  ; set space criteria block, with a metadata filter
  expression1 = aurorax_create_metadata_filter_expression('nbtrace_region', ['north polar cap'], /operator_in)
  expression2 = aurorax_create_metadata_filter_expression('nbtrace_region', ['north auroral oval'], /operator_in)
  expressions = list(expression1, expression2)
  metadata_filters = aurorax_create_metadata_filter(expressions, /operator_and)
  space = list(aurorax_create_criteria_block(programs = ['swarm'], metadata_filters = metadata_filters, /space))

  ; perform search
  print, '[Multiple expressions example - part A] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Multiple expressions example - part A] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'

  ; You'll notice that we found zero conjunctions! This is a 'duh' moment if we take a step back for
  ; a second...a spacecraft cannot be in both the north polar cap AND the north auroral oval at the same
  ; time!
  ;
  ; What if we tweak this to find conjunctions where Swarm was in the north auroral oval, and the TII
  ; instrument was collecting data? We have this instrument operating information only for Swarm right
  ; now, but maybe we'll have more in the future!
  expression1 = aurorax_create_metadata_filter_expression('nbtrace_region', 'north auroral oval', /operator_eq)
  expression2 = aurorax_create_metadata_filter_expression('tii_on', 'true', /operator_eq)
  expressions = list(expression1, expression2)
  metadata_filters = aurorax_create_metadata_filter(expressions, /operator_and)
  space = list(aurorax_create_criteria_block(programs = ['swarm'], metadata_filters = metadata_filters, /space))

  ; perform search
  print, '[Multiple expressions example - part B] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Multiple expressions example - part B] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''

  ; Great, we found some conjunctions!
  ;
  ; Remember with most conjunction searches, you can view the results directly in Swarm-Aurora using the
  ; `aurorax_open_conjunctions_in_swarmaurora` function. More info can be found in the conjunction searching
  ; example.
end

pro aurorax_example_advanced_metadata_filter_searching4
  ; find conjunctions with Swarm where the UCalgary cloud ML model thinks any THEMIS ASI data
  ; is not cloudy and that classification has a confidence of >= 75%.
  ;
  ; set timeframe and distance
  start_dt = '2020-01-01T00:00:00'
  end_dt = '2020-01-15T23:59:59'
  distance = 500

  ; set ground criteria block
  expressions = list( $
    aurorax_create_metadata_filter_expression('calgary_cloud_ml_v1', 'classified as not cloudy', /operator_in), $
    aurorax_create_metadata_filter_expression('calgary_cloud_ml_v1_confidence', 75, /operator_ge))
  metadata_filters = aurorax_create_metadata_filter(expressions, /operator_and)
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], metadata_filters = metadata_filters, /ground))

  ; set space criteria block, with a metadata filter
  space = list(aurorax_create_criteria_block(programs = ['swarm'], hemisphere = ['northern'], /space))

  ; perform search
  print, '[Numerical example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Numerical example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_advanced_metadata_filter_searching5
  ; find conjunctions with Swarm where the UCalgary cloud ML model thinks any THEMIS ASI data
  ; is not cloudy and that classification has a confidence of between 75% and 90%.
  ;
  ; set timeframe and distance
  start_dt = '2020-01-01T00:00:00'
  end_dt = '2020-01-15T23:59:59'
  distance = 500

  ; set ground criteria block
  expressions = list( $
    aurorax_create_metadata_filter_expression('calgary_cloud_ml_v1', 'classified as not cloudy', /operator_in), $
    aurorax_create_metadata_filter_expression('calgary_cloud_ml_v1_confidence', [75, 90], /operator_between))
  metadata_filters = aurorax_create_metadata_filter(expressions, /operator_and)
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], metadata_filters = metadata_filters, /ground))

  ; set space criteria block, with a metadata filter
  space = list(aurorax_create_criteria_block(programs = ['swarm'], hemisphere = ['northern'], /space))

  ; perform search
  print, '[Between operator example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Between operator example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end
