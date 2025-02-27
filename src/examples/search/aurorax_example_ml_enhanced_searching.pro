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

pro aurorax_example_ml_enhanced_searching
  ; ----------------------------------
  ; Introduction
  ; ----------------------------------
  ;
  ; Integrated with the AuroraX search engine, there is the ability to search through ephemeris and
  ; conjunctions based on various machine learning model metadata that has been uploaded to the platform.
  ;
  ; Two use cases to highlight, but there are many more:
  ;
  ; - finding all conjunctions between spacecrafts and the THEMIS ASIs where an ML model believes
  ; it is not cloudy in the THEMIS ASI
  ;
  ; - retrieve all 1-minute times where an ML model believes THEMIS ASIs have Amorphous Pulsating
  ; Aurora (APA) in the field of view.
  ;
  ; More information about the available ML metadata can be found at https://docs.aurorax.space/ml/overview
  ;
  ; Let's first have a look at how to do conjunction searches, and find results by leveraging some ML-derived
  ; metadata.
  ;
  ; ----------------------------------
  ; Conjunction search - UCalgary Amorphous Pulsating Aurora (APA) model
  ; ----------------------------------
  ;
  ; UCalgary has developed a machine learning model for identifying Amorphous Pulsating Aurora (APA) in the
  ; THEMIS all-sky imagers. This is a binary classification performed on a 10-minute basis, and included in
  ; all THEMIS ASI AuroraX search engine 'ephemeris' records as a metadata field.
  ;
  ; Metadata fields in AuroraX can be searched upon, allowing users to filter results based on them. Below,
  ; we're going to show an example of finding all 1-minute ephemeris records for any THEMIS ASI instrument
  ; where this particular model thinks there is APA in the field-of-view for that camera, over a 1 month
  ; period.
  ;
  ; More information about this model can be found at https://docs.aurorax.space/ml/models/ucalgary_apa/
  aurorax_example_ml_enhanced_searching1

  ; ----------------------------------
  ; Conjunction search - UCalgary cloud model
  ; ----------------------------------
  ;
  ; UCalgary has developed a machine learning model for identifying cloud in the THEMIS all-sky imagers. This
  ; is a binary classification performed on a 10-minute basis, and included in all THEMIS ASI AuroraX search
  ; engine 'ephemeris' records as a metadata field.
  ;
  ; Below, we're going to show an example of finding all 1-minute ephemeris records for any THEMIS ASI
  ; instrument where this particular model thinks there is cloud in the field-of-view at Gillam, over a 7 day
  ; period.
  ;
  ; More information about this model can be found at https://docs.aurorax.space/ml/models/ucalgary_cloud/
  aurorax_example_ml_enhanced_searching2

  ; ----------------------------------
  ; Conjunction search - Oslo Aurora THEMIS (OATH) model
  ; ----------------------------------
  ;
  ; The OATH model was developed by Clausen & Nickisch (https://doi.org/10.1029/2018JA025274), and has been
  ; run by the AuroraX team for all THEMIS ASI data in the AuroraX search engine.
  ;
  ; - Paper: https://doi.org/10.1029/2018JA025274
  ; - More information: http://tid.uio.no/plasma/oath
  ;
  ; This paper has two versions of the model, one that is a binary classifier (aurora/no aurora), and one that
  ; is a 6-class classifier. AuroraX currently only contains metadata derived from the 6-class model.
  ;
  ; The OATH mode is a binary classification performed on a 10-minute basis, and included in all THEMIS ASI
  ; AuroraX search engine 'ephemeris' records as a metadata field.
  ;
  ; Below, we're going to show an example of finding all 1-minute ephemeris records for any THEMIS ASI instrument
  ; where the OATH model has classified the minute as diffuse or discrete aurora, over a 1 day period.
  ;
  ; More information about the AuroraX utilization of this model can be found at
  ; https://docs.aurorax.space/ml/models/clausen_oath/
  aurorax_example_ml_enhanced_searching3

  ; ----------------------------------
  ; Ephemeris search
  ; ----------------------------------
  ;
  ; Now we'll have a look at a few examples of ephemeris searches using metadata filters for ML-derived values.
  ;
  ; APA model
  aurorax_example_ml_enhanced_searching4

  ; cloud model
  aurorax_example_ml_enhanced_searching5

  ; OATH model
  aurorax_example_ml_enhanced_searching6
end

pro aurorax_example_ml_enhanced_searching1
  ; Do a conjunction search with the UCalgary APA model
  ;
  ; set up search parameters
  start_dt = '2008-01-01T00:00'
  end_dt = '2008-01-31T23:59'
  distance = 500

  ; create ground criteria block with metadata filters -- classified as APA, confidence is >=95%
  expression_1 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1', 'classified as APA', /operator_eq)
  expression_2 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1_confidence', 95, /operator_ge)
  expressions = list(expression_1, expression_2)
  metadata_filters = aurorax_create_metadata_filter(expressions, /operator_and)
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], metadata_filters = metadata_filters, /ground))

  ; create space criteria block
  space = list(aurorax_create_criteria_block(programs = ['themis'], hemisphere = ['northern'], /space))

  ; perform search
  print, '[Conjunction search - UCalgary APA example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Conjunction search - UCalgary APA example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''

  ; Remember with most conjunction searches, you can view the results directly in Swarm-Aurora using
  ; the `aurorax_open_conjunctions_in_swarmaurora` function. More info can be found in the conjunction
  ; searching examples.
end

pro aurorax_example_ml_enhanced_searching2
  ; Do a conjunction search with the UCalgary cloud model
  ;
  ; set up search parameters
  start_dt = '2020-01-01TT00:00'
  end_dt = '2020-01-15T23:59'
  distance = 500

  ; create ground criteria block with metadata filters -- classified as not cloud, confidence is >=75%
  expression_1 = aurorax_create_metadata_filter_expression('calgary_cloud_ml_v1', 'classified as not cloudy', /operator_eq)
  expression_2 = aurorax_create_metadata_filter_expression('calgary_cloud_ml_v1_confidence', 75, /operator_ge)
  expressions = list(expression_1, expression_2)
  metadata_filters = aurorax_create_metadata_filter(expressions, /operator_and)
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], metadata_filters = metadata_filters, /ground))

  ; create space criteria block
  space = list(aurorax_create_criteria_block(programs = ['swarm', 'elfin'], hemisphere = ['northern'], /space))

  ; perform search
  print, '[Conjunction search - UCalgary cloud example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Conjunction search - UCalgary cloud example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_ml_enhanced_searching3
  ; Do a conjunction search with the OATH model
  ;
  ; set up search parameters
  start_dt = '2015-01-01TT00:00'
  end_dt = '2015-01-31T23:59'
  distance = 500

  ; create ground criteria block with metadata filters -- OATH classified as either diffuse, discrete, or arc
  expressions = list(aurorax_create_metadata_filter_expression( $
    'clausen_ml_oath', $
    ['classified as diffuse', 'classified as discrete', 'classified as arc'], $
    /operator_in))
  metadata_filters = aurorax_create_metadata_filter(expressions, /operator_and)
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], metadata_filters = metadata_filters, /ground))

  ; create space criteria block
  space = list(aurorax_create_criteria_block(programs = ['dmsp'], hemisphere = ['northern'], /space))

  ; perform search
  print, '[Conjunction search - OATH example] Starting search ...'
  r = aurorax_conjunction_search(start_dt, end_dt, distance, ground = ground, space = space, /nbtrace, /quiet)
  print, '[Conjunction search - OATH example] Found ' + string(n_elements(r.data), format = '(I0)') + ' conjunctions'
  print, ''
end

pro aurorax_example_ml_enhanced_searching4
  ; Do an ephemeris search for records classified as APA
  ;
  ; set search parameters
  start_ts = '2008-01-05T00:00'
  end_ts = '2008-01-05T23:59'
  programs = ['themis-asi']

  ; set metadata filter
  expressions = list( $
    aurorax_create_metadata_filter_expression('calgary_apa_ml_v1', 'classified as APA', /operator_eq), $
    aurorax_create_metadata_filter_expression('calgary_apa_ml_v1_confidence', 95, /operator_ge))
  metadata_filters = aurorax_create_metadata_filter(expressions)

  ; perform search
  print, '[Ephemeris search - UCalgary APA example] Starting search ...'
  r = aurorax_ephemeris_search(start_ts, end_ts, programs = programs, metadata_filters = metadata_filters, /quiet)
  print, '[Ephemeris search - UCalgary APA example] Found ' + string(n_elements(r.data), format = '(I0)') + ' ephemeris records'
  print, ''
end

pro aurorax_example_ml_enhanced_searching5
  ; Do an ephemeris search for records classified as not cloud
  ;
  ; set search parameters
  start_ts = '2008-01-02T00:00'
  end_ts = '2008-01-02T23:59'
  programs = ['themis-asi']
  platforms = ['gillam']

  ; set metadata filter
  expressions = list( $
    aurorax_create_metadata_filter_expression('calgary_cloud_ml_v1', 'classified as not cloudy', /operator_eq), $
    aurorax_create_metadata_filter_expression('calgary_cloud_ml_v1_confidence', 75, /operator_ge))
  metadata_filters = aurorax_create_metadata_filter(expressions)

  ; perform search
  print, '[Ephemeris search - UCalgary cloud example] Starting search ...'
  r = aurorax_ephemeris_search(start_ts, end_ts, programs = programs, platforms = platforms, metadata_filters = metadata_filters, /quiet)
  print, '[Ephemeris search - UCalgary cloud example] Found ' + string(n_elements(r.data), format = '(I0)') + ' ephemeris records'
  print, ''
end

pro aurorax_example_ml_enhanced_searching6
  ; Do an ephemeris search for records classified with the OATH model
  ;
  ; set search parameters
  start_ts = '2008-01-01T06:00'
  end_ts = '2008-01-01T06:59'
  programs = ['themis-asi']

  ; set metadata filter
  expressions = list(aurorax_create_metadata_filter_expression( $
    'clausen_ml_oath', $
    ['classified as diffuse', 'classified as discrete', 'classified as arc'], $
    /operator_eq))
  metadata_filters = aurorax_create_metadata_filter(expressions)

  ; perform search
  print, '[Ephemeris search - OATH example] Starting search ...'
  r = aurorax_ephemeris_search(start_ts, end_ts, programs = programs, metadata_filters = metadata_filters, /quiet)
  print, '[Ephemeris search - OATH example] Found ' + string(n_elements(r.data), format = '(I0)') + ' ephemeris records'
  print, ''
end
