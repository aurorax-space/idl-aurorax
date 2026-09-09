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
; Tests for aurorax_create_criteria_block -- the four shapes of criteria
; block the search engine accepts, and the defaults each one carries.

pro aurorax_test_criteria_blocks
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'criteria blocks -- ground'
  ; -----------------------------------------------------------
  cb = aurorax_create_criteria_block(programs = ['themis-asi'], /ground)
  atest_not_null, cb, 'a ground block is created'
  atest_has_tag, cb, 'programs', 'ground block has programs'
  atest_has_tag, cb, 'platforms', 'ground block has platforms'
  atest_has_tag, cb, 'instrument_types', 'ground block has instrument_types'
  atest_has_tag, cb, 'ephemeris_metadata_filters', 'ground block has ephemeris_metadata_filters'
  atest_n_elements, cb.programs, 1, 'the supplied program is stored'
  atest_equal, cb.programs[0], 'themis-asi', 'the program value round trips'
  atest_n_elements, cb.platforms, 0, 'platforms defaults to empty'
  atest_n_elements, cb.instrument_types, 0, 'instrument_types defaults to empty'

  ; a ground block has no hemisphere -- that is a space-only concept
  names = tag_names(cb)
  atest_equal, (where(names eq 'HEMISPHERE'))[0], -1, 'ground block has no hemisphere tag'

  cb = aurorax_create_criteria_block(programs = ['themis-asi', 'rego'], $
    platforms = ['fort smith', 'gillam'], $
    instrument_types = ['RGB ASI'], /ground)
  atest_n_elements, cb.programs, 2, 'multiple programs are stored'
  atest_n_elements, cb.platforms, 2, 'multiple platforms are stored'
  atest_n_elements, cb.instrument_types, 1, 'instrument types are stored'
  atest_equal, cb.platforms[1], 'gillam', 'platform values keep their order'

  ; -----------------------------------------------------------
  atest_suite, 'criteria blocks -- space'
  ; -----------------------------------------------------------
  cb = aurorax_create_criteria_block(programs = ['swarm'], /space)
  atest_not_null, cb, 'a space block is created'
  atest_has_tag, cb, 'hemisphere', 'space block has a hemisphere tag'
  atest_n_elements, cb.instrument_types, 1, 'space block defaults instrument_types to a single entry'
  atest_equal, cb.instrument_types[0], 'footprint', 'space block defaults its instrument type to footprint'
  atest_n_elements, cb.hemisphere, 0, 'hemisphere defaults to empty'

  cb = aurorax_create_criteria_block(programs = ['swarm'], hemisphere = ['northern'], /space)
  atest_n_elements, cb.hemisphere, 1, 'a supplied hemisphere is stored'
  atest_equal, cb.hemisphere[0], 'northern', 'the hemisphere value round trips'

  cb = aurorax_create_criteria_block(programs = ['swarm'], hemisphere = ['northern', 'southern'], /space)
  atest_n_elements, cb.hemisphere, 2, 'both hemispheres can be requested'

  ; -----------------------------------------------------------
  atest_suite, 'criteria blocks -- events'
  ; -----------------------------------------------------------
  cb = aurorax_create_criteria_block(instrument_types = ['substorm onset'], /events)
  atest_not_null, cb, 'an events block is created'
  atest_n_elements, cb.programs, 1, 'events block defaults its program list to a single entry'
  atest_equal, cb.programs[0], 'events', 'events block defaults its program to "events"'
  atest_equal, cb.instrument_types[0], 'substorm onset', 'the instrument type round trips'

  ; an explicitly supplied program replaces the default
  cb = aurorax_create_criteria_block(programs = ['custom-list'], instrument_types = ['substorm onset'], /events)
  atest_equal, cb.programs[0], 'custom-list', 'an explicit program overrides the events default'

  ; -----------------------------------------------------------
  atest_suite, 'criteria blocks -- custom locations'
  ; -----------------------------------------------------------
  cb = aurorax_create_criteria_block(locations = list([51.05, -114.07]), /custom)
  atest_not_null, cb, 'a custom locations block is created'
  atest_has_tag, cb, 'locations', 'custom block has a locations tag'
  atest_n_elements, cb.locations, 1, 'one location was stored'
  atest_close, (cb.locations[0]).lat, 51.05, 0.001, 'latitude is taken from the first element'
  atest_close, (cb.locations[0]).lon, -114.07, 0.001, 'longitude is taken from the second element'

  cb = aurorax_create_criteria_block(locations = list([51.05, -114.07], [58.75, -94.06]), /custom)
  atest_n_elements, cb.locations, 2, 'multiple locations are stored'
  atest_close, (cb.locations[1]).lat, 58.75, 0.001, 'the second location keeps its latitude'

  ; a custom block carries nothing but locations
  atest_equal, n_tags(cb), 1, 'a custom block has exactly one tag'

  ; -----------------------------------------------------------
  atest_suite, 'criteria blocks -- metadata filters are attached'
  ; -----------------------------------------------------------
  expressions = list(aurorax_create_metadata_filter_expression('nbtrace_region', 'north polar cap', /operator_eq))
  mf = aurorax_create_metadata_filter(expressions)

  cb = aurorax_create_criteria_block(programs = ['swarm'], metadata_filters = mf, /space)
  atest_not_null, cb.ephemeris_metadata_filters, 'a space block accepts metadata filters'
  atest_has_key, cb.ephemeris_metadata_filters, 'EXPRESSIONS', 'the filter expressions are attached'

  cb = aurorax_create_criteria_block(programs = ['themis-asi'], metadata_filters = mf, /ground)
  atest_has_key, cb.ephemeris_metadata_filters, 'EXPRESSIONS', 'a ground block accepts metadata filters too'

  ; without filters the hash is present but empty, so callers can always
  ; check hasKey without worrying about the tag being absent
  cb = aurorax_create_criteria_block(programs = ['themis-asi'], /ground)
  atest_n_elements, cb.ephemeris_metadata_filters, 0, 'metadata filters default to an empty hash'

  ; -----------------------------------------------------------
  atest_suite, 'criteria blocks -- no type keyword'
  ; -----------------------------------------------------------
  atest_note, 'the next call prints a "no valid keyword" error -- that output is expected'
  cb = aurorax_create_criteria_block(programs = ['themis-asi'])
  atest_null, cb, 'omitting the block type keyword returns !null'
end
