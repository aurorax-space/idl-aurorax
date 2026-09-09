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
; Network tests. These talk to api.aurorax.space and
; api.phys.ucalgary.ca, so they are skipped unless the runner is given
; /online:
;
;   IDL> aurorax_run_tests, /online
;
; The suite is named with an _online suffix, which is how the runner knows
; to skip it by default. Keep the queries here small and cheap -- the point
; is to prove the client and the API still agree on request and response
; shapes, not to exercise the search engine.
;
; A failure here is as likely to mean the API changed, or the network is
; down, as it is to mean the library broke.

pro aurorax_test_api_online
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'online -- data source listing'
  ; -----------------------------------------------------------
  sources = aurorax_list_sources(program = 'swarm')
  atest_not_null, sources, 'the API returns Swarm data sources'
  if (n_elements(sources) ne 0) then begin
    atest_true, n_elements(sources) gt 0, 'at least one Swarm source came back'

    ; the fields the search helpers rely on
    s = sources[0]
    atest_has_tag, s, 'identifier', 'a source carries an identifier'
    atest_has_tag, s, 'program', 'a source carries a program'
    atest_has_tag, s, 'platform', 'a source carries a platform'
    atest_has_tag, s, 'instrument_type', 'a source carries an instrument type'
    atest_equal, strlowcase(s.program), 'swarm', 'the program filter was applied'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'online -- dataset listing'
  ; -----------------------------------------------------------
  datasets = aurorax_list_datasets(name = 'THEMIS_ASI_RAW')
  atest_not_null, datasets, 'the API returns the THEMIS ASI raw dataset'
  if (n_elements(datasets) ne 0) then begin
    atest_true, n_elements(datasets) gt 0, 'at least one dataset came back'
    d = datasets[0]
    atest_has_tag, d, 'name', 'a dataset carries a name'

    ; whatever the archive says is readable, the local check should agree
    atest_true, aurorax_ucalgary_is_read_supported(d.name), $
      'the dataset the API returned is one the reader supports'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'online -- conjunction search describe'
  ; -----------------------------------------------------------
  ;
  ; describe is the cheapest way to prove the API accepts the query shape
  ; the client builds -- it validates and explains the query without
  ; actually running a search
  ground = list(aurorax_create_criteria_block(programs = ['themis-asi'], /ground))
  space = list(aurorax_create_criteria_block(programs = ['swarm'], /space))

  description = aurorax_conjunction_describe('2020-01-01T00:00:00', '2020-01-01T23:59:59', 500, $
    ground = ground, space = space, /nbtrace)
  atest_not_null, description, 'the API describes a conjunction query'
  if (n_elements(description) ne 0) then begin
    atest_true, strlen(description) gt 0, 'the description is not empty'
    atest_contains, strlowcase(description), 'themis-asi', 'the description mentions the ground program'
    atest_contains, strlowcase(description), 'swarm', 'the description mentions the space program'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'online -- sub-minute precision is accepted'
  ; -----------------------------------------------------------
  ;
  ; The whole point of the subminute_precision field is that the API
  ; understands it. If the API were to reject or ignore an unknown field,
  ; this is where that would show up.
  description = aurorax_conjunction_describe('2020-01-01T00:00:00', '2020-01-01T23:59:59', 500, $
    ground = ground, space = space, /nbtrace, /subminute_precision)
  atest_not_null, description, 'the API accepts a query carrying subminute_precision'
  if (n_elements(description) ne 0) then begin
    atest_true, strlen(description) gt 0, 'the sub-minute description is not empty'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'online -- availability'
  ; -----------------------------------------------------------
  availability = aurorax_ephemeris_availability('2020-01-01', '2020-01-01', program = 'swarm')
  atest_not_null, availability, 'the API returns ephemeris availability'
  if (n_elements(availability) gt 0) then begin
    atest_true, n_elements(availability) gt 0, 'at least one availability record came back'
  endif

  ; -----------------------------------------------------------
  atest_suite, 'online -- version check'
  ; -----------------------------------------------------------
  ;
  ; this one reaches GitHub rather than the AuroraX API
  info = aurorax_check_version(/quiet)
  atest_not_null, info, 'the version check returns something'
  if (n_elements(info) ne 0) then begin
    ; on success it returns a struct; on failure it returns the scalar -1
    if (size(info, /type) eq 8) then begin
      atest_has_tag, info, 'new_version_available', 'the version check reports whether an update exists'
      atest_has_tag, info, 'curr_version', 'the version check reports the current version'
      atest_has_tag, info, 'latest_version', 'the version check reports the latest version'
      atest_equal, info.curr_version, __aurorax_version(), $
        'the reported current version matches the library'
    endif else begin
      atest_note, 'the version check could not reach GitHub -- skipping its assertions'
    endelse
  endif
end
