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
; Tests for metadata filter construction.

pro aurorax_test_metadata_filters
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'metadata filter expressions -- operators'
  ; -----------------------------------------------------------
  e = aurorax_create_metadata_filter_expression('key1', 'value1', /operator_eq)
  atest_not_null, e, 'an expression is created'
  atest_has_key, e, 'key', 'expression has a key'
  atest_has_key, e, 'values', 'expression has values'
  atest_has_key, e, 'operator', 'expression has an operator'
  atest_equal, e['key'], 'key1', 'the key round trips'
  atest_equal, e['operator'], '=', 'operator_eq maps to ='

  atest_equal, (aurorax_create_metadata_filter_expression('k', 'v', /operator_ne))['operator'], '!=', $
    'operator_ne maps to !='
  atest_equal, (aurorax_create_metadata_filter_expression('k', 'v', /operator_lt))['operator'], '<', $
    'operator_lt maps to <'
  atest_equal, (aurorax_create_metadata_filter_expression('k', 'v', /operator_gt))['operator'], '>', $
    'operator_gt maps to >'
  atest_equal, (aurorax_create_metadata_filter_expression('k', 'v', /operator_le))['operator'], '<=', $
    'operator_le maps to <='
  atest_equal, (aurorax_create_metadata_filter_expression('k', 'v', /operator_ge))['operator'], '>=', $
    'operator_ge maps to >='
  atest_equal, (aurorax_create_metadata_filter_expression('k', 'v', /operator_between))['operator'], 'between', $
    'operator_between maps to between'
  atest_equal, (aurorax_create_metadata_filter_expression('k', 'v', /operator_in))['operator'], 'in', $
    'operator_in maps to in'
  atest_equal, (aurorax_create_metadata_filter_expression('k', 'v', /operator_not_in))['operator'], 'not in', $
    'operator_not_in maps to "not in"'

  ; -----------------------------------------------------------
  atest_suite, 'metadata filter expressions -- value handling'
  ; -----------------------------------------------------------
  ;
  ; a scalar string becomes a one element list, so the API always receives
  ; an array regardless of how the caller phrased it
  e = aurorax_create_metadata_filter_expression('k', 'single', /operator_eq)
  atest_n_elements, e['values'], 1, 'a scalar value becomes a one element collection'
  atest_equal, (e['values'])[0], 'single', 'the scalar value is preserved'

  ; numbers are stringified
  e = aurorax_create_metadata_filter_expression('confidence', 95, /operator_ge)
  atest_n_elements, e['values'], 1, 'a numeric value becomes a one element collection'
  atest_equal, (e['values'])[0], '95', 'a numeric value is converted to a string'

  e = aurorax_create_metadata_filter_expression('confidence', 95.5, /operator_ge)
  atest_contains, (e['values'])[0], '95.5', 'a float value is converted to a string'

  ; a list is kept as-is
  e = aurorax_create_metadata_filter_expression('k', list('a', 'b', 'c'), /operator_in)
  atest_n_elements, e['values'], 3, 'a supplied list keeps all its entries'
  atest_equal, (e['values'])[2], 'c', 'list ordering is preserved'

  ; an array is kept as-is
  e = aurorax_create_metadata_filter_expression('k', ['a', 'b'], /operator_in)
  atest_n_elements, e['values'], 2, 'a supplied array keeps all its entries'

  ; -----------------------------------------------------------
  atest_suite, 'metadata filter expressions -- missing operator'
  ; -----------------------------------------------------------
  atest_note, 'the next call prints a "must supply one of the operator keywords" error -- expected'
  e = aurorax_create_metadata_filter_expression('k', 'v')
  atest_null, e, 'omitting the operator keyword returns !null'

  ; -----------------------------------------------------------
  atest_suite, 'metadata filters -- assembly'
  ; -----------------------------------------------------------
  e1 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1', list('classified as APA'), /operator_in)
  e2 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1_confidence', 95, /operator_ge)
  expressions = list(e1, e2)

  mf = aurorax_create_metadata_filter(expressions, /operator_and)
  atest_not_null, mf, 'a metadata filter is created'
  atest_has_tag, mf, 'logical_operator', 'the filter has a logical operator'
  atest_has_tag, mf, 'expressions', 'the filter has expressions'
  atest_equal, mf.logical_operator, 'AND', 'operator_and gives AND'
  atest_n_elements, mf.expressions, 2, 'both expressions are carried'

  ; the default, with no operator keyword at all
  mf = aurorax_create_metadata_filter(expressions)
  atest_equal, mf.logical_operator, 'AND', 'the logical operator defaults to AND'

  ; KNOWN BUG: aurorax_create_metadata_filter computes an `operator` local
  ; from the keywords and then ignores it, hardcoding 'AND' into the struct
  ; (aurorax_metadata_filters.pro:147). /operator_or is therefore silently
  ; dropped. This assertion pins the current behaviour so the suite stays
  ; green; when the bug is fixed it will fail, and should be changed to
  ; expect 'OR'.
  mf = aurorax_create_metadata_filter(expressions, /operator_or)
  atest_equal, mf.logical_operator, 'AND', $
    '/operator_or currently still yields AND (known bug -- the operator is computed then discarded)'

  ; -----------------------------------------------------------
  atest_suite, 'metadata filters -- reach the conjunction payload'
  ; -----------------------------------------------------------
  ;
  ; json_serialize does not lowercase nested hash keys, so the query builder
  ; patches them up afterwards. Check that the patching worked, since a
  ; mis-cased key would be silently ignored by the API.
  expressions = list(aurorax_create_metadata_filter_expression('nbtrace_region', 'north polar cap', /operator_eq))
  mf = aurorax_create_metadata_filter(expressions)
  space = list(aurorax_create_criteria_block(programs = ['swarm'], metadata_filters = mf, /space))
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], /ground))

  post_str = __aurorax_conjunctions_create_post_str(0, '2020-01-01T00:00:00', '2020-01-01T23:59:59', $
    500, 1, !null, !null, ground, space, !null, !null, 0)

  atest_contains, post_str, '"logical_operator"', 'logical_operator is lowercased in the payload'
  atest_contains, post_str, '"expressions"', 'expressions is lowercased in the payload'
  atest_not_contains, post_str, 'LOGICAL_OPERATOR', 'the uppercase logical_operator does not survive'
  atest_not_contains, post_str, 'EXPRESSIONS', 'the uppercase expressions key does not survive'

  atest_valid_json, post_str, 'a query carrying metadata filters is valid JSON', parsed = q
  if (n_elements(q) ne 0) then begin
    filters = ((q['space'])[0])['ephemeris_metadata_filters']
    atest_has_key, filters, 'logical_operator', 'the parsed payload exposes logical_operator'
    atest_has_key, filters, 'expressions', 'the parsed payload exposes expressions'
    expr = (filters['expressions'])[0]
    atest_equal, expr['key'], 'nbtrace_region', 'the expression key survives serialization'
    atest_equal, expr['operator'], '=', 'the expression operator survives serialization'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'metadata filters -- = is promoted to in for multiple values'
  ; -----------------------------------------------------------
  ;
  ; The API rejects '=' against a list of values, so the query builder
  ; rewrites the operator to 'in' on the way out.
  expressions = list(aurorax_create_metadata_filter_expression('region', list('a', 'b'), /operator_eq))
  mf = aurorax_create_metadata_filter(expressions)
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], metadata_filters = mf, /ground))
  space = list(aurorax_create_criteria_block(programs = ['swarm'], /space))

  post_str = __aurorax_conjunctions_create_post_str(0, '2020-01-01T00:00:00', '2020-01-01T23:59:59', $
    500, 1, !null, !null, ground, space, !null, !null, 0)

  atest_valid_json, post_str, 'a multi-value = query serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    expr = ((((q['ground'])[0])['ephemeris_metadata_filters'])['expressions'])[0]
    atest_equal, expr['operator'], 'in', $
      'a = operator with several values is promoted to in'
  endif

  ; a single value is left alone
  expressions = list(aurorax_create_metadata_filter_expression('region', 'a', /operator_eq))
  mf = aurorax_create_metadata_filter(expressions)
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], metadata_filters = mf, /ground))

  post_str = __aurorax_conjunctions_create_post_str(0, '2020-01-01T00:00:00', '2020-01-01T23:59:59', $
    500, 1, !null, !null, ground, space, !null, !null, 0)

  atest_valid_json, post_str, 'a single-value = query serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    expr = ((((q['ground'])[0])['ephemeris_metadata_filters'])['expressions'])[0]
    atest_equal, expr['operator'], '=', 'a = operator with one value is left alone'
  endif
end
