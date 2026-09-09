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
; Tests for conjunction search query construction.
;
; These call __aurorax_conjunctions_create_post_str directly rather than
; going through aurorax_conjunction_search with /dryrun. Same code path, but
; the helper hands back the JSON string instead of printing it, so the
; payload can actually be asserted on.

;+
; Build a post string with the usual defaults, so the individual tests only
; have to say what is different about them.
;-
function __atest_conj_query, $
  ground = ground, $
  space = space, $
  events = events, $
  custom = custom, $
  distance = distance, $
  nbtrace = nbtrace, $
  sbtrace = sbtrace, $
  geographic = geographic, $
  subminute = subminute, $
  start_ts = start_ts, $
  end_ts = end_ts
  compile_opt idl2

  if (n_elements(start_ts) eq 0) then start_ts = '2020-01-01T00:00:00'
  if (n_elements(end_ts) eq 0) then end_ts = '2020-01-01T23:59:59'
  if (n_elements(distance) eq 0) then distance = 500
  if (n_elements(subminute) eq 0) then subminute = 0

  return, __aurorax_conjunctions_create_post_str(0, $
    start_ts, $
    end_ts, $
    distance, $
    nbtrace, $
    sbtrace, $
    geographic, $
    ground, $
    space, $
    events, $
    custom, $
    subminute)
end

pro aurorax_test_conjunction_query
  compile_opt idl2

  ; a pair of criteria blocks reused throughout
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], /ground))
  space = list(aurorax_create_criteria_block(programs = ['swarm'], /space))

  ; -----------------------------------------------------------
  atest_suite, 'conjunction query -- basic payload'
  ; -----------------------------------------------------------
  post_str = __atest_conj_query(ground = ground, space = space, nbtrace = 1)
  atest_valid_json, post_str, 'query serializes to valid JSON', parsed = q

  if (n_elements(q) ne 0) then begin
    atest_has_key, q, 'start', 'payload carries a start timestamp'
    atest_has_key, q, 'end', 'payload carries an end timestamp'
    atest_equal, q['start'], '2020-01-01T00:00:00', 'start timestamp is the parsed ISO form'
    atest_equal, q['end'], '2020-01-01T23:59:59', 'end timestamp is the parsed ISO form'

    ; 'end' is a reserved word as an IDL struct tag, so the builder assembles
    ; the struct with an 'end_ts' tag and rewrites it on the way out. Make
    ; sure that rewrite actually happened.
    atest_false, q.hasKey('end_ts'), 'the end_ts placeholder tag does not leak into the payload'

    atest_has_key, q, 'ground', 'payload carries ground criteria blocks'
    atest_has_key, q, 'space', 'payload carries space criteria blocks'
    atest_has_key, q, 'events', 'payload carries an events list'
    atest_has_key, q, 'adhoc', 'custom locations are sent under the adhoc key'
    atest_has_key, q, 'max_distances', 'payload carries max distances'
    atest_has_key, q, 'conjunction_types', 'payload carries conjunction types'

    atest_n_elements, q['ground'], 1, 'one ground criteria block'
    atest_n_elements, q['space'], 1, 'one space criteria block'
    atest_n_elements, q['events'], 0, 'no events criteria blocks'
    atest_n_elements, q['adhoc'], 0, 'no custom location criteria blocks'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'conjunction query -- conjunction types'
  ; -----------------------------------------------------------
  post_str = __atest_conj_query(ground = ground, space = space, nbtrace = 1)
  atest_valid_json, post_str, 'nbtrace only serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_n_elements, q['conjunction_types'], 1, 'nbtrace only -> one conjunction type'
    atest_equal, q['conjunction_types', 0], 'nbtrace', 'nbtrace only -> nbtrace'
  endif

  post_str = __atest_conj_query(ground = ground, space = space, sbtrace = 1)
  atest_valid_json, post_str, 'sbtrace only serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_equal, q['conjunction_types', 0], 'sbtrace', 'sbtrace only -> sbtrace'
  endif

  post_str = __atest_conj_query(ground = ground, space = space, geographic = 1)
  atest_valid_json, post_str, 'geographic only serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_equal, q['conjunction_types', 0], 'geographic', 'geographic only -> geographic'
  endif

  post_str = __atest_conj_query(ground = ground, space = space, nbtrace = 1, sbtrace = 1, geographic = 1)
  atest_valid_json, post_str, 'all three types serialize', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_n_elements, q['conjunction_types'], 3, 'all three conjunction types requested'
  endif

  post_str = __atest_conj_query(ground = ground, space = space)
  atest_valid_json, post_str, 'no conjunction type keywords serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_n_elements, q['conjunction_types'], 0, 'no keywords -> empty conjunction types list'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'conjunction query -- sub-minute precision'
  ; -----------------------------------------------------------
  ;
  ; The API defaults to one-minute precision. The field is only sent when the
  ; caller explicitly asks for sub-minute, so that the API keeps ownership of
  ; the default.
  post_str = __atest_conj_query(ground = ground, space = space, nbtrace = 1, subminute = 0)
  atest_valid_json, post_str, 'query without sub-minute serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_false, q.hasKey('subminute_precision'), $
      'subminute_precision is omitted entirely when not requested'
  endif
  atest_not_contains, post_str, 'subminute', 'the string form carries no mention of sub-minute either'

  post_str = __atest_conj_query(ground = ground, space = space, nbtrace = 1, subminute = 1)
  atest_valid_json, post_str, 'query with sub-minute serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_has_key, q, 'subminute_precision', 'subminute_precision is present when requested'
    atest_true, q['subminute_precision'], 'subminute_precision is true when requested'
  endif

  ; it must serialize as a JSON boolean, not as the integer 1 or the string "1"
  atest_contains, post_str, '"subminute_precision":true', $
    'subminute_precision serializes as a JSON boolean'

  ; enabling it must not disturb anything else about the query
  atest_valid_json, post_str, 'sub-minute query is still well formed', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_equal, q['start'], '2020-01-01T00:00:00', 'start timestamp unaffected by sub-minute'
    atest_n_elements, q['ground'], 1, 'ground blocks unaffected by sub-minute'
    atest_n_elements, q['conjunction_types'], 1, 'conjunction types unaffected by sub-minute'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'conjunction query -- distances'
  ; -----------------------------------------------------------
  post_str = __atest_conj_query(ground = ground, space = space, nbtrace = 1, distance = 500)
  atest_valid_json, post_str, 'scalar distance serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    d = q['max_distances']
    atest_has_key, d, 'ground1-space1', 'a scalar distance is expanded into the ground1-space1 pairing'
    atest_equal, d['ground1-space1'], 500, 'the pairing carries the supplied distance'
    atest_n_elements, d, 1, 'one ground and one space block produce exactly one pairing'
  endif

  ; a hash of distances is passed through as given
  distances = aurorax_create_advanced_distances_hash(300, ground_count = 1, space_count = 1)
  post_str = __atest_conj_query(ground = ground, space = space, nbtrace = 1, distance = distances)
  atest_valid_json, post_str, 'hash distance serializes', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_equal, (q['max_distances'])['ground1-space1'], 300, 'a supplied distances hash is used as-is'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'conjunction query -- timestamps are parsed, not passed through'
  ; -----------------------------------------------------------
  post_str = __atest_conj_query(ground = ground, space = space, nbtrace = 1, $
    start_ts = '2020', end_ts = '2020')
  atest_valid_json, post_str, 'shorthand timestamps serialize', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_equal, q['start'], '2020-01-01T00:00:00', 'shorthand start expands to the beginning of the year'
    atest_equal, q['end'], '2020-12-31T23:59:59', 'shorthand end expands to the end of the year'
  endif

  ; second-level timestamps survive, which is what makes sub-minute searching useful
  post_str = __atest_conj_query(ground = ground, space = space, nbtrace = 1, $
    start_ts = '2020-01-01T00:00:15', end_ts = '2020-01-01T00:02:45', subminute = 1)
  atest_valid_json, post_str, 'second-level timestamps serialize', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_equal, q['start'], '2020-01-01T00:00:15', 'start seconds reach the payload intact'
    atest_equal, q['end'], '2020-01-01T00:02:45', 'end seconds reach the payload intact'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'conjunction query -- criteria block limits'
  ; -----------------------------------------------------------
  ;
  ; the search engine allows at most 10 criteria blocks
  many_ground = list()
  for i = 0, 10 do many_ground.add, aurorax_create_criteria_block(programs = ['themis-asi'], /ground)
  atest_n_elements, many_ground, 11, 'built 11 criteria blocks for the over-limit case'

  atest_note, 'the builder prints a "too many criteria blocks" error below -- that output is expected'
  post_str = __atest_conj_query(ground = many_ground, nbtrace = 1)
  atest_equal, typename(post_str), 'LIST', '11 criteria blocks is rejected, returning an empty list'
  atest_n_elements, post_str, 0, 'the rejection result is empty'

  ; exactly 10 is fine
  ten_ground = list()
  for i = 0, 8 do ten_ground.add, aurorax_create_criteria_block(programs = ['themis-asi'], /ground)
  post_str = __atest_conj_query(ground = ten_ground, space = space, nbtrace = 1)
  atest_valid_json, post_str, '10 criteria blocks is accepted', parsed = q
  if (n_elements(q) ne 0) then begin
    atest_n_elements, q['ground'], 9, 'all nine ground blocks are present'
  endif

  ; a conjunction needs two things to be in conjunction, so one block is
  ; refused up front rather than faulting inside the distances helper
  atest_note, 'the next two calls print "not enough criteria blocks" errors -- that output is expected'
  post_str = __atest_conj_query(ground = ground, nbtrace = 1)
  atest_equal, typename(post_str), 'LIST', 'a single criteria block is rejected'
  atest_n_elements, post_str, 0, 'the rejection result is empty'

  post_str = __atest_conj_query(nbtrace = 1)
  atest_equal, typename(post_str), 'LIST', 'no criteria blocks at all is rejected'

  ; -----------------------------------------------------------
  atest_suite, 'conjunction query -- bad distance argument'
  ; -----------------------------------------------------------
  ;
  ; a distance that is neither a number nor a pairings hash used to fall
  ; through both branches and leave the distances undefined, faulting when
  ; the request struct was assembled
  atest_note, 'the next call prints a "distance must be a number or a hash" error -- expected'
  post_str = __atest_conj_query(ground = ground, space = space, nbtrace = 1, distance = 'far')
  atest_equal, typename(post_str), 'LIST', 'a string distance is rejected'
  atest_n_elements, post_str, 0, 'the rejection result is empty'
end
