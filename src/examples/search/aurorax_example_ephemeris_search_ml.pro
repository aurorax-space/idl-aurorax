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

pro aurorax_example_ephemeris_search_ml
  ; ----------------------------------
  ; EXAMPLE 1 -- searching ephemeris data and filtering on the UCalgary APA model
  ;
  ; More information about this model: https://docs.aurorax.space/ml/models/ucalgary_apa/
  ; ----------------------------------
  ;
  ; To begin, let's do an ephemeris search for some THEMIS ASI data.

  ; We will search for any data between these dates, at Gillam
  start_search_date = '2008-01-01T00:00'
  end_search_date = '2008-01-31T23:59'

  ; Now, to filter based on ML data, we need to set up some metadata
  ; filters. This can be done using the below functions. Let's filter
  ; to only retrieve records where the 'calgary_apa_ml_v1' field is
  ; 'classified as APA', with a confidence greater than or equal to 95%.
  ;
  ; For this, we create two metadata 'expressions', store them in a list
  ; and use the helper function to convert into the proper metadata format.
  expression_1 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1', 'classified as APA', /operator_eq)
  expression_2 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1_confidence', 95, /operator_ge)
  expressions = list(expression_1, expression_2)
  metadata_filters = aurorax_create_metadata_filter(expressions, /operator_and)

  ; Now we can do our search. Again, we search between our start and end
  ; dates, for themis-asi at gillam
  response = aurorax_ephemeris_search(start_search_date, $
    end_search_date, $
    programs = ['themis-asi'], $
    platforms = ['gillam'], $
    instrument_types = ['panchromatic ASI'], $
    metadata_filters = metadata_filters)

  ; The resulting data will list all records in which our metadata filter holds true
  help, response.data

  ; Print some info on a couple records
  print
  print, 'calgary_apa_ml_v1 search results'
  print
  print, '    Epoch                Classification        Confidence (%)'
  print, '================================================================='
  for i = 0, 18, 9 do begin
    epoch = response.data[i].epoch
    classification = response.data[i].metadata.calgary_apa_ml_v1
    confidence = string(response.data[i].metadata.calgary_apa_ml_v1_confidence, format = '(d6.2)')
    print, epoch + '     ' + classification + '          ' + confidence
  endfor
  print
  print

  ; ----------------------------------
  ; EXAMPLE 2 -- searching ephemeris data and filtering on the UCalgary cloud model
  ;
  ; More information about this model: https://docs.aurorax.space/ml/models/ucalgary_cloud/
  ; ----------------------------------
  ;
  ; Let's create a new search fo a shorter time range, and search for data from the same
  ; site, but filter based on clouds. We will search for data that was classified
  ; as not cloudy, with a confidence of at least 75%
  start_search_date = '2008-01-01T00:00'
  end_search_date = '2008-01-07T23:59'

  ; Again, we create our new metadata filters using helper functions
  expression_1 = aurorax_create_metadata_filter_expression('calgary_cloud_ml_v1', 'classified as not cloudy', /operator_eq)
  expression_2 = aurorax_create_metadata_filter_expression('calgary_cloud_ml_v1_confidence', 75, /operator_ge)
  expressions = list(expression_1, expression_2)
  metadata_filters = aurorax_create_metadata_filter(expressions, /operator_and)

  ; Now we can do our new search
  response = aurorax_ephemeris_search(start_search_date, $
    end_search_date, $
    programs = ['themis-asi'], $
    platforms = ['gillam'], $
    instrument_types = ['panchromatic ASI'], $
    metadata_filters = metadata_filters)

  ; Print some info on a couple records
  print
  print, 'calgary_cloud_ml_v1 search results'
  print
  print, '    Epoch                Classification                 Confidence (%)'
  print, '=========================================================================='
  for i = 0, 18, 9 do begin
    epoch = response.data[i].epoch
    classification = response.data[i].metadata.calgary_cloud_ml_v1
    confidence = string(response.data[i].metadata.calgary_cloud_ml_v1_confidence, format = '(d6.2)')
    print, epoch + '     ' + classification + '          ' + confidence
  endfor
  print
  print

  ; ----------------------------------
  ; EXAMPLE 3 -- searching ephemeris data and filtering on the OATH model
  ;
  ; More information about this model:
  ; - AuroraX usage: https://docs.aurorax.space/ml/models/clausen_oath/
  ; - Paper: https://doi.org/10.1029/2018JA025274
  ; ----------------------------------
  ;
  ; Let's create one more search. This time, we will filter only for
  ; discrete or diffuse aurora, using the OATH model results.
  start_search_date = '2008-01-01T00:00'
  end_search_date = '2008-01-07T23:59'

  ; Again, we create our new metadata filters using helper functions
  expression = aurorax_create_metadata_filter_expression('clausen_ml_oath', list('classified as diffuse', 'classified as discrete'), /operator_in)
  expressions = list(expression)
  metadata_filters = aurorax_create_metadata_filter(expressions)

  ; Now we can do our new search.
  response = aurorax_ephemeris_search(start_search_date, $
    end_search_date, $
    programs = ['themis-asi'], $
    platforms = ['gillam'], $
    instrument_types = ['panchromatic ASI'], $
    metadata_filters = metadata_filters)

  ; Print some info on a couple records
  print
  print, 'clausen_ml_oath search results'
  print
  print, '    Epoch                   Classification'
  print, '================================================='
  for i = 0, 18, 9 do begin
    epoch = response.data[i].epoch
    classification = response.data[i].metadata.clausen_ml_oath
    print, epoch + '     ' + classification
  endfor
  print
end
