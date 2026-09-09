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
;
; Tests for ephemeris and data product query construction. Like the
; conjunction query tests, these call the private post-string builders so
; the payload can be inspected instead of merely printed.

pro aurorax_test_ephemeris_query
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'ephemeris query -- basic payload'
  ; -----------------------------------------------------------
  post_str = __aurorax_ephemeris_create_post_str(0, '2020-01-01T00:00:00', '2020-01-01T23:59:59', $
    ['swarm'], ['swarma'], ['footprint'], !null)

  atest_valid_json, post_str, 'the ephemeris query is valid JSON', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_has_key, q, 'start', 'payload carries a start timestamp'
    atest_has_key, q, 'end', 'payload carries an end timestamp'
    atest_equal, q['start'], '2020-01-01T00:00:00', 'the start timestamp is the parsed ISO form'
    atest_equal, q['end'], '2020-01-01T23:59:59', 'the end timestamp is the parsed ISO form'
    atest_false, q.hasKey('end_ts'), 'the end_ts placeholder tag does not leak into the payload'

    atest_has_key, q, 'data_sources', 'payload carries data sources'
    ds = q['data_sources']
    atest_has_key, ds, 'programs', 'data sources carry programs'
    atest_has_key, ds, 'platforms', 'data sources carry platforms'
    atest_has_key, ds, 'instrument_types', 'data sources carry instrument types'
    atest_equal, (ds['programs'])[0], 'swarm', 'the program round trips'
    atest_equal, (ds['platforms'])[0], 'swarma', 'the platform round trips'
    atest_equal, (ds['instrument_types'])[0], 'footprint', 'the instrument type round trips'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'ephemeris query -- timestamps are parsed'
  ; -----------------------------------------------------------
  post_str = __aurorax_ephemeris_create_post_str(0, '2020', '2020', ['swarm'], !null, !null, !null)
  atest_valid_json, post_str, 'shorthand timestamps serialize', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_equal, q['start'], '2020-01-01T00:00:00', 'the shorthand start expands to the start of the year'
    atest_equal, q['end'], '2020-12-31T23:59:59', 'the shorthand end expands to the end of the year'
  endif

  ; a malformed timestamp stops the query being built at all
  ;
  ; NOTE: the input has to be genuinely unparseable. Something like
  ; 'not-a-date' is not -- the parser strips the dashes first, leaving
  ; eight characters, which it happily reads as yyyymmdd.
  atest_note, 'the next call prints a malformed datetime error -- that output is expected'
  result = __aurorax_ephemeris_create_post_str(0, 'xyz', '2020', ['swarm'], !null, !null, !null)
  atest_equal, typename(result), 'LIST', 'an unparseable timestamp yields an empty list'
  atest_n_elements, result, 0, 'the rejection result is empty'

  ; -----------------------------------------------------------
  atest_suite, 'ephemeris query -- metadata filters'
  ; -----------------------------------------------------------
  expressions = list(aurorax_create_metadata_filter_expression('nbtrace_region', 'north polar cap', /operator_eq))
  mf = aurorax_create_metadata_filter(expressions)

  post_str = __aurorax_ephemeris_create_post_str(0, '2020-01-01T00:00:00', '2020-01-01T23:59:59', $
    ['swarm'], !null, !null, mf)

  atest_contains, post_str, '"logical_operator"', 'logical_operator is lowercased'
  atest_contains, post_str, '"expressions"', 'expressions is lowercased'
  atest_not_contains, post_str, 'LOGICAL_OPERATOR', 'the uppercase form does not survive'

  atest_valid_json, post_str, 'a filtered ephemeris query is valid JSON', parsed = q
  if (n_elements(q) ne 0) then begin
    filters = (q['data_sources'])['ephemeris_metadata_filters']
    atest_has_key, filters, 'expressions', 'the filter expressions reach the payload'
    expr = (filters['expressions'])[0]
    atest_equal, expr['key'], 'nbtrace_region', 'the expression key survives'
  endif

  ; the same '=' to 'in' promotion the conjunction builder does
  expressions = list(aurorax_create_metadata_filter_expression('region', list('a', 'b'), /operator_eq))
  mf = aurorax_create_metadata_filter(expressions)
  post_str = __aurorax_ephemeris_create_post_str(0, '2020-01-01T00:00:00', '2020-01-01T23:59:59', $
    ['swarm'], !null, !null, mf)

  atest_valid_json, post_str, 'a multi-value filtered query serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    expr = (((q['data_sources'])['ephemeris_metadata_filters'])['expressions'])[0]
    atest_equal, expr['operator'], 'in', 'a = operator with several values is promoted to in'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'data product query -- basic payload'
  ; -----------------------------------------------------------
  post_str = __aurorax_data_product_create_post_str(0, '2020-01-01T00:00:00', '2020-01-01T23:59:59', $
    ['themis-asi'], ['gillam'], ['panchromatic ASI'], !null, !null)

  atest_valid_json, post_str, 'the data product query is valid JSON', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_has_key, q, 'start', 'payload carries a start timestamp'
    atest_has_key, q, 'end', 'payload carries an end timestamp'
    atest_has_key, q, 'data_sources', 'payload carries data sources'
    atest_equal, q['start'], '2020-01-01T00:00:00', 'the start timestamp is the parsed ISO form'

    ds = q['data_sources']
    atest_equal, (ds['programs'])[0], 'themis-asi', 'the program round trips'
    atest_equal, (ds['platforms'])[0], 'gillam', 'the platform round trips'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'data product query -- data product type filter'
  ; -----------------------------------------------------------
  ;
  ; Regression test. The filter used to be assigned onto data_sources_struct,
  ; which has no such tag -- so supplying data_product_types faulted, and
  ; would have been a no-op even if the tag had existed, since post_struct
  ; was already built by value. It now goes onto post_struct directly.
  post_str = __aurorax_data_product_create_post_str(0, '2020-01-01T00:00:00', '2020-01-01T23:59:59', $
    ['themis-asi'], !null, !null, ['keogram'], !null)

  atest_valid_json, post_str, 'a query with a data product type filter serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_has_key, q, 'data_product_type_filters', 'the payload carries a data product type filter'
    atest_n_elements, q['data_product_type_filters'], 1, 'one data product type was requested'
    atest_equal, (q['data_product_type_filters'])[0], 'keogram', 'the requested type reaches the payload'
  endif

  ; several types at once
  post_str = __aurorax_data_product_create_post_str(0, '2020-01-01T00:00:00', '2020-01-01T23:59:59', $
    ['themis-asi'], !null, !null, ['keogram', 'montage'], !null)

  atest_valid_json, post_str, 'a query with several data product types serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_n_elements, q['data_product_type_filters'], 2, 'both data product types were carried'
    atest_equal, (q['data_product_type_filters'])[1], 'montage', 'the second type keeps its place'
  endif

  ; omitting the filter leaves the list empty rather than absent, so the API
  ; always sees a well formed field
  post_str = __aurorax_data_product_create_post_str(0, '2020-01-01T00:00:00', '2020-01-01T23:59:59', $
    ['themis-asi'], !null, !null, !null, !null)

  atest_valid_json, post_str, 'a query with no data product type filter serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_has_key, q, 'data_product_type_filters', 'the field is present even when unused'
    atest_n_elements, q['data_product_type_filters'], 0, 'and is empty when unused'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'availability -- date validation happens before any request'
  ; -----------------------------------------------------------
  ;
  ; Both availability entry points parse their dates up front and bail out
  ; with an empty result. That is what keeps this test offline, so the input
  ; has to be one the parser genuinely rejects -- anything it can coerce
  ; into a date would send a real request to the API.
  atest_note, 'the next two calls print malformed datetime errors -- that output is expected'
  r = aurorax_ephemeris_availability('xyz', 'xyz', program = 'swarm')
  atest_n_elements, r, 0, 'ephemeris availability rejects unparseable dates without a request'

  r = aurorax_data_products_availability('xyz', 'xyz', program = 'themis-asi')
  atest_n_elements, r, 0, 'data product availability rejects unparseable dates without a request'
end
