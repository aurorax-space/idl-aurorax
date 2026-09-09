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
; Tests for the advanced distances machinery. A conjunction search needs a
; maximum distance for every unordered pair of criteria blocks, and these
; routines work out what those pairs are.

;+
; Is `key` one of the hash's keys?
;-
function __atest_hash_has, h, key
  compile_opt idl2

  return, h.hasKey(key) ? 1 : 0
end

pro aurorax_test_distances
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'derive distances -- pair counts'
  ; -----------------------------------------------------------
  ;
  ; n blocks produce n*(n-1)/2 unordered pairs
  pairs = __aurorax_derive_advanced_distances(ground_count = 1, space_count = 1)
  atest_n_elements, pairs, 1, '1 ground + 1 space -> 1 pair'

  pairs = __aurorax_derive_advanced_distances(ground_count = 2, space_count = 1)
  atest_n_elements, pairs, 3, '2 ground + 1 space -> 3 pairs'

  pairs = __aurorax_derive_advanced_distances(ground_count = 2, space_count = 2)
  atest_n_elements, pairs, 6, '2 ground + 2 space -> 6 pairs'

  pairs = __aurorax_derive_advanced_distances(ground_count = 1, space_count = 3)
  atest_n_elements, pairs, 6, '1 ground + 3 space -> 6 pairs'

  pairs = __aurorax_derive_advanced_distances(ground_count = 1, space_count = 1, events_count = 1, custom_count = 1)
  atest_n_elements, pairs, 6, 'one of each block type -> 6 pairs'

  ; -----------------------------------------------------------
  atest_suite, 'derive distances -- pair naming'
  ; -----------------------------------------------------------
  pairs = __aurorax_derive_advanced_distances(ground_count = 1, space_count = 1)
  atest_equal, pairs[0], 'ground1-space1', 'the single pair is named ground1-space1'

  pairs = __aurorax_derive_advanced_distances(ground_count = 2, space_count = 2)
  as_hash = hash(pairs.toArray(), intarr(n_elements(pairs)))
  atest_true, __atest_hash_has(as_hash, 'ground1-ground2'), 'ground to ground pair is present'
  atest_true, __atest_hash_has(as_hash, 'ground1-space1'), 'ground1 to space1 pair is present'
  atest_true, __atest_hash_has(as_hash, 'ground1-space2'), 'ground1 to space2 pair is present'
  atest_true, __atest_hash_has(as_hash, 'ground2-space1'), 'ground2 to space1 pair is present'
  atest_true, __atest_hash_has(as_hash, 'ground2-space2'), 'ground2 to space2 pair is present'
  atest_true, __atest_hash_has(as_hash, 'space1-space2'), 'space to space pair is present'

  ; pairs are unordered -- only one direction is emitted
  atest_false, __atest_hash_has(as_hash, 'space1-ground1'), 'the reversed pairing is not also emitted'

  ; events blocks are named "events", custom blocks are named "adhoc"
  pairs = __aurorax_derive_advanced_distances(space_count = 1, events_count = 1)
  atest_equal, pairs[0], 'space1-events1', 'events blocks are named events<n>'

  pairs = __aurorax_derive_advanced_distances(space_count = 1, custom_count = 1)
  atest_equal, pairs[0], 'space1-adhoc1', 'custom location blocks are named adhoc<n>'

  ; -----------------------------------------------------------
  atest_suite, 'derive distances -- block count limits'
  ; -----------------------------------------------------------
  ;
  ; fewer than 2 or more than 10 blocks is refused, and the refusal is
  ; signalled by handing back an empty hash instead of a list
  atest_note, 'the next few calls print "must have between 2 and 10" errors -- that output is expected'

  result = __aurorax_derive_advanced_distances(ground_count = 1)
  atest_n_elements, result, 0, 'a single block is refused'
  atest_equal, typename(result), 'HASH', 'the refusal is signalled with an empty hash'

  result = __aurorax_derive_advanced_distances()
  atest_n_elements, result, 0, 'no blocks at all is refused'

  result = __aurorax_derive_advanced_distances(ground_count = 11)
  atest_n_elements, result, 0, 'eleven blocks is refused'

  ; ten is the documented maximum and must be accepted
  result = __aurorax_derive_advanced_distances(ground_count = 5, space_count = 5)
  atest_n_elements, result, 45, 'ten blocks is accepted, giving 45 pairs'
  atest_equal, typename(result), 'LIST', 'an accepted request comes back as a list'

  ; -----------------------------------------------------------
  atest_suite, 'create distances hash'
  ; -----------------------------------------------------------
  d = aurorax_create_advanced_distances_hash(500, ground_count = 1, space_count = 1)
  atest_equal, typename(d), 'HASH', 'a hash is returned'
  atest_n_elements, d, 1, 'one pairing for one ground and one space block'
  atest_equal, d['ground1-space1'], 500, 'the pairing carries the requested distance'

  d = aurorax_create_advanced_distances_hash(750, ground_count = 2, space_count = 2)
  atest_n_elements, d, 6, 'six pairings for two ground and two space blocks'
  atest_equal, d['ground1-ground2'], 750, 'every pairing gets the same default distance'
  atest_equal, d['space1-space2'], 750, 'including the space to space pairing'

  ; the returned hash is meant to be edited before use -- setting a pairing
  ; to !null tells the search engine to ignore that distance
  d['ground1-ground2'] = !null
  atest_n_elements, d['ground1-ground2'], 0, 'a pairing can be cleared to !null'
  atest_n_elements, d, 6, 'clearing a pairing does not remove the key'

  ; -----------------------------------------------------------
  atest_suite, 'create distances hash -- invalid block counts'
  ; -----------------------------------------------------------
  ;
  ; Regression test. An out of range block count used to fault here: the
  ; derive function hands back an empty hash, and this routine went on to
  ; build a zero-length array from it and index the result. It now returns
  ; !null, which a caller can actually check.
  atest_note, 'the next few calls print "must have between 2 and 10" errors -- that output is expected'
  atest_null, aurorax_create_advanced_distances_hash(500, ground_count = 1), $
    'a single block returns !null rather than faulting'
  atest_null, aurorax_create_advanced_distances_hash(500, ground_count = 11), $
    'eleven blocks returns !null rather than faulting'
  atest_null, aurorax_create_advanced_distances_hash(500), $
    'no blocks at all returns !null'

  ; -----------------------------------------------------------
  atest_suite, 'validate distances'
  ; -----------------------------------------------------------
  d = aurorax_create_advanced_distances_hash(500, ground_count = 2, space_count = 1)
  atest_true, __aurorax_validate_advanced_distances(d, ground_count = 2, space_count = 1), $
    'a complete distances hash validates'

  ; drop a pairing and it should no longer validate
  atest_note, 'the next call prints a "does not have all expected pairings" error -- expected'
  d.remove, 'ground1-ground2'
  atest_false, __aurorax_validate_advanced_distances(d, ground_count = 2, space_count = 1), $
    'a distances hash missing a pairing does not validate'

  ; a hash built for a different block layout does not validate either
  atest_note, 'the next call prints a "does not have all expected pairings" error -- expected'
  d = aurorax_create_advanced_distances_hash(500, ground_count = 1, space_count = 1)
  atest_false, __aurorax_validate_advanced_distances(d, ground_count = 2, space_count = 2), $
    'a hash for a smaller layout does not validate against a larger one'
end
