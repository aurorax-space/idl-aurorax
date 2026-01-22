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

function __aurorax_derive_advanced_distances, $
  ground_count = ground_count, $
  space_count = space_count, $
  events_count = events_count, $
  custom_count = custom_count
  ; initialize values that aren't entered
  if (isa(ground_count) eq 0) then ground_count = 0
  if (isa(space_count) eq 0) then space_count = 0
  if (isa(events_count) eq 0) then events_count = 0
  if (isa(custom_count) eq 0) then custom_count = 0

  ; check to make sure there's between 2 and 10
  criteria_block_count = ground_count + space_count + events_count + custom_count
  if (criteria_block_count lt 2 or criteria_block_count gt 10) then begin
    print, 'Error generating distance mappings: must have between 2 and 10 total criteria blocks, got ' + $
      string(criteria_block_count, format = '(I0)')
    return, hash()
  endif

  ; set input arrays
  options = list()
  for i = 1, ground_count do begin
    options.add, 'ground' + strtrim(i, 2)
  endfor
  for i = 1, space_count do begin
    options.add, 'space' + strtrim(i, 2)
  endfor
  for i = 1, events_count do begin
    options.add, 'events' + strtrim(i, 2)
  endfor
  for i = 1, custom_count do begin
    options.add, 'adhoc' + strtrim(i, 2)
  endfor

  ; derive all combinations of options of size 2
  combinations = list()
  for i = 0, n_elements(options) - 1 do begin
    for j = 0, n_elements(options) - 1 do begin
      if (i ne j) then begin
        combo = options[i] + '-' + options[j]
        combo_reversed = options[j] + '-' + options[i]
        if (combinations.where(combo) eq !null and combinations.where(combo_reversed) eq !null) then begin
          ; not already in the list, add it
          combinations.add, combo
        endif
      endif
    endfor
  endfor

  ; return
  return, combinations
end

function __aurorax_validate_advanced_distances, $
  distance, $
  ground_count = ground_count, $
  space_count = space_count, $
  events_count = events_count, $
  custom_count = custom_count
  ; initialize values that aren't entered
  if (isa(ground_count) eq 0) then ground_count = 0
  if (isa(space_count) eq 0) then space_count = 0
  if (isa(events_count) eq 0) then events_count = 0
  if (isa(custom_count) eq 0) then custom_count = 0

  ; get expected pairings
  expected_pairings = __aurorax_derive_advanced_distances(ground_count = ground_count, $
    space_count = space_count, $
    events_count = events_count, $
    custom_count = custom_count)

  ; cross-check expected pairings with what was supplied
  supplied_keys = distance.keys()
  for i = 0, n_elements(expected_pairings) - 1 do begin
    if (supplied_keys.where(expected_pairings[i]) eq !null) then begin
      ; found an expected pair that was not included in the supplied distances hash, throw error
      print, 'Error: distances hash does not have all expected pairings, missing ''' + expected_pairings[i] + ''''
      return, 0
    endif
  endfor

  ; is valid
  return, 1
end

;+
; :Description:
;       Create advanced distances pairing for a conjunction search.
;
;       The AuroraX conjunction search requires distance pairings for every
;       possibility of criteria blocks. This function will generate all
;       possibilities for you.
;
;       The function returns the advanced distances, as a hash with the default
;       value for each value being the 'distance' variable supplied.
;
; :Parameters:
;       distance: in, required, Integer
;         default distance for each pairing
;
; :Keywords:
;       ground_count: in, optional, Integer
;         number of ground criteria blocks
;       space_count: in, optional, Integer
;         number of space criteria blocks
;       events_count: in, optional, Integer
;         number of events criteria blocks
;       custom_count: in, optional, Integer
;         number of custom locations criteria blocks
;
; :Returns:
;       Hash
;
; :Examples:
;       distances = aurorax_create_advanced_distances_hash(500, ground_count=1, space_count=2)
;       distances = aurorax_create_advanced_distances_hash(500, space_count=1, events_count=1)
;       distances = aurorax_create_advanced_distances_hash(500, space_count=1, custom_count=1)
;+
function aurorax_create_advanced_distances_hash, distance, $
  ground_count = ground_count, $
  space_count = space_count, $
  events_count = events_count, $
  custom_count = custom_count
  ; initialize values that aren't entered
  if (isa(ground_count) eq 0) then ground_count = 0
  if (isa(space_count) eq 0) then space_count = 0
  if (isa(events_count) eq 0) then events_count = 0
  if (isa(custom_count) eq 0) then custom_count = 0

  ; get pairings
  keys = __aurorax_derive_advanced_distances(ground_count = ground_count, $
    space_count = space_count, $
    events_count = events_count, $
    custom_count = custom_count)

  ; create hash object
  values = intarr(n_elements(keys))
  for i = 0, n_elements(values) - 1 do begin
    values[i] = distance
  endfor
  distances = hash(keys, values)

  ; return
  return, distances
end

function __aurorax_conjunctions_create_post_str, $
  verbose, $
  start_ts, $
  end_ts, $
  distance, $
  ct_nbtrace, $
  ct_sbtrace, $
  ct_geo, $
  ground, $
  space, $
  events, $
  custom_locations
  ; get ISO datetime strings
  if (verbose eq 1) then __aurorax_message, 'Parsing start and end timestamps'
  start_iso_dt = __aurorax_datetime_parser(start_ts, /interpret_as_start)
  end_iso_dt = __aurorax_datetime_parser(end_ts, /interpret_as_end)
  if (start_iso_dt eq '' or end_iso_dt eq '') then return, list()

  ; check criteria block count validity
  criteria_block_count = n_elements(ground) + n_elements(space) + n_elements(events) + n_elements(custom_locations)
  if (criteria_block_count gt 10) then begin
    __aurorax_message, 'Error: too many criteria blocks, max of 10 is allowed and ' + string(criteria_block_count, format = '(I0)') + $
      ' have been supplied. Please reduce the count and try again.'
    return, list()
  endif

  ; set distance
  if (isa(distance, /integer) eq 1 or isa(distance, /float) eq 1) then begin
    ; entered distance is a single number, use that to generate all the max distance pairings
    distances_hash = aurorax_create_advanced_distances_hash(distance, $
      ground_count = n_elements(ground), $
      space_count = n_elements(space), $
      events_count = n_elements(events), $
      custom_count = n_elements(custom_locations))
  endif else if (isa(distance, 'HASH') eq 1) then begin
    ; entered distance is the correct object type, make sure it has all the correct pairings
    distances_valid = __aurorax_validate_advanced_distances(distance, $
      ground_count = n_elements(ground), $
      space_count = n_elements(space), $
      events_count = n_elements(events), $
      custom_count = n_elements(custom_locations))
    if (distances_valid eq 1) then begin
      distances_hash = distance
    endif else begin
      __aurorax_message, 'Error: distances object is not valid, update your distances object ' + $
        'and try again (in most cases, the object is missing pairings)'
      return, list()
    endelse
  endif

  ; set conjunction types
  conjunction_types = list()
  if keyword_set(ct_nbtrace) then conjunction_types.add, 'nbtrace'
  if keyword_set(ct_sbtrace) then conjunction_types.add, 'sbtrace'
  if keyword_set(ct_geo) then conjunction_types.add, 'geographic'

  ; check all metadata filter expression operators
  ;
  ; NOTE: if there are multiple values and the operator is '=', it needs to be changed
  ; to be 'in'.
  for i = 0, n_elements(ground) - 1 do begin
    if (ground[i].ephemeris_metadata_filters.hasKey('EXPRESSIONS')) then begin
      for j = 0, n_elements(ground[i].ephemeris_metadata_filters['EXPRESSIONS']) - 1 do begin
        this_expr = ground[i].ephemeris_metadata_filters['EXPRESSIONS', j]
        if (n_elements(this_expr['values']) gt 1 and this_expr['operator'] eq '=') then begin
          ; has multiple values but operator is '=', change it to 'in'
          ground[i].ephemeris_metadata_filters['EXPRESSIONS', j, 'operator'] = 'in'
        endif
      endfor
    endif
  endfor
  for i = 0, n_elements(space) - 1 do begin
    if (space[i].ephemeris_metadata_filters.hasKey('EXPRESSIONS')) then begin
      for j = 0, n_elements(space[i].ephemeris_metadata_filters['EXPRESSIONS']) - 1 do begin
        this_expr = space[i].ephemeris_metadata_filters['EXPRESSIONS', j]
        if (n_elements(this_expr['values']) gt 1 and this_expr['operator'] eq '=') then begin
          ; has multiple values but operator is '=', change it to 'in'
          space[i].ephemeris_metadata_filters['EXPRESSIONS', j, 'operator'] = 'in'
        endif
      endfor
    endif
  endfor
  for i = 0, n_elements(events) - 1 do begin
    if (events[i].ephemeris_metadata_filters.hasKey('EXPRESSIONS')) then begin
      for j = 0, n_elements(events[i].ephemeris_metadata_filters['EXPRESSIONS']) - 1 do begin
        this_expr = events[i].ephemeris_metadata_filters['EXPRESSIONS', j]
        if (n_elements(this_expr['values']) gt 1 and this_expr['operator'] eq '=') then begin
          ; has multiple values but operator is '=', change it to 'in'
          events[i].ephemeris_metadata_filters['EXPRESSIONS', j, 'operator'] = 'in'
        endif
      endfor
    endif
  endfor

  ; create data sources struct
  if (verbose eq 1) then __aurorax_message, 'Creating request struct'
  post_struct = {start: start_iso_dt, $
    end_ts: end_iso_dt, $
    ground: list(), $
    space: list(), $
    events: list(), $
    adhoc: list(), $
    conjunction_types: list(), $
    max_distances: distances_hash}
  if (isa(ground) eq 1) then post_struct.ground = ground
  if (isa(space) eq 1) then post_struct.space = space
  if (isa(events) eq 1) then post_struct.events = events
  if (isa(custom_locations) eq 1) then post_struct.adhoc = custom_locations
  post_struct.conjunction_types = conjunction_types
  post_struct.max_distances = distances_hash

  ; serialize into a string
  post_str = json_serialize(post_struct, /lowercase)
  post_str = post_str.replace('LOGICAL_OPERATOR', 'logical_operator') ; because of a bug in json_serialize where it doesn't lowercase nested hashes
  post_str = post_str.replace('EXPRESSIONS', 'expressions') ; because of a bug in json_serialize where it doesn't lowercase nested hashes
  post_str = post_str.replace('end_ts', 'end') ; because 'end' isn't a valid struct tag name

  ; return
  return, post_str
end

;+
; :Description:
;       Search the AuroraX platform for conjunctions using the supplied filter criteria.
;       This function returns the found conjunctions, as a search response struct. If the
;       'response_format' parameter is supplied, data will be returned as a hash.
;
;       The 'start_ts' and 'end_ts' parameters are to be timestamps in a variety of formats. The
;       following are examples of what is allowed:
;
;       The following are all interpreted as '2020-01-01T00:00:00':
;         start_ts = '2020'
;         start_ts = '202001'
;         start_ts = '20200101'
;         start_ts = '2020010100'
;         start_ts = '202001010000'
;         start_ts = '2020-01-01'
;         start_ts = '2020/01/01T00:00'
;         start_ts = '2020-01-01 00:00'
;
;       The following are all interpreted as '2020-12-31T23:59:59':
;         end_ts = '2020'
;         end_ts = '202012'
;         end_ts = '20201231'
;         end_ts = '2020123123'
;         end_ts = '202012312359'
;         end_ts = '2020-12-31'
;         end_ts = '2020/12/31T23'
;         end_ts = '2020-12-31 23'

; :Parameters:
;       start_ts: in, required, String
;         start datetime, string (different formats allowed, see above)
;       end_ts: in, required, String
;         end datetime, string (different formats allowed, see above)
;       distance: in, required, Integer or Hash
;         max distance between criteria blocks, integer or hash
;
; :Keywords:
;       ground: in, optional, List
;         ground criteria blocks
;       space: in, optional, List
;         space criteria blocks
;       events: in, optional, List
;         events criteria blocks
;       custom_locations: in, optional, List
;         custom locations criteria blocks
;       poll_interval: in, optional, Integer
;         sleep time between polling events while waiting for data (in seconds; default is 1s)
;       nbtrace: in, optional, Boolean
;         search for north B-trace conjunctions
;       sbtrace: in, optional, Boolean
;         search for south B-trace conjunctions
;       geographic: in, optional, Boolean
;         search for geographic conjunctions
;       quiet: in, optional, Boolean
;         quiet output when searching, no print messages will be shown
;       dryrun: in, optional, Boolean
;         run in dry-run mode, which will exit before sending the search
;         request to AuroraX. The query will be printed though, so that
;         users can check to make sure it would have sent the request
;         that they wanted it to send.
;
; :Returns:
;       Struct, Hash
;
; :Examples:
;       ; simple example
;       distance = 500
;       start_ts = '2019-01-01T00:00:00'
;       end_ts = '2019-01-03T23:59:59'
;       ground1 = aurorax_create_criteria_block(programs=['themis-asi'],platforms=['fort smith', 'gillam'],/GROUND)
;       ground = list(ground1)
;       space1 = aurorax_create_criteria_block(programs=['swarm'],hemisphere=['northern'],/SPACE)
;       space = list(space1)
;       response = aurorax_conjunction_search(start_ts,end_ts,distance,ground=ground,space=space,/nbtrace)
;
;       ; example with metadata
;       distance = 500
;       start_ts = '2008-01-01T00:00:00'
;       end_ts = '2008-01-31T23:59:59'
;       expression1 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1', list('classified as APA'),/OPERATOR_IN)
;       expression2 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1_confidence', 95,/OPERATOR_GE)
;       expressions = list(expression1, expression2)
;       ground_metadata_filters = aurorax_create_metadata_filter(expressions,/OPERATOR_AND)
;       ground1 = aurorax_create_criteria_block(programs=['themis-asi'],metadata_filters=ground_metadata_filters,/GROUND)
;       ground = list(ground1)
;       space1 = aurorax_create_criteria_block(programs=['themis'],hemisphere=['northern'],/SPACE)
;       space = list(space1)
;       response = aurorax_conjunction_search(start_ts,end_ts,distance,ground=ground,space=space,/nbtrace)
;+
function aurorax_conjunction_search, $
  start_ts, $
  end_ts, $
  distance, $
  ground = ground, $
  space = space, $
  events = events, $
  custom_locations = custom_locations, $
  response_format = response_format, $
  poll_interval = pi, $
  nbtrace = ct_nbtrace, $
  sbtrace = ct_sbtrace, $
  geographic = ct_geo, $
  quiet = q, $
  dryrun = dr
  ; set verbosity
  verbose = 1
  if (isa(q) eq 1) then verbose = 0

  ; set poll interval
  poll_interval = 1
  if (isa(pi) eq 1) then poll_interval = pi

  ; set dry run flag
  dry_run = 0
  if (isa(dr) eq 1) then dry_run = 1
  if (verbose eq 1 and dry_run eq 1) then __aurorax_message, 'Executing in dry-run mode'

  ; construct post structure
  post_str = __aurorax_conjunctions_create_post_str(verbose, $
    start_ts, $
    end_ts, $
    distance, $
    ct_nbtrace, $
    ct_sbtrace, $
    ct_geo, $
    ground, $
    space, $
    events, $
    custom_locations)

  ; stop here if in dry-run mode
  if (dry_run eq 1) then begin
    __aurorax_message, 'Dry-run mode, stopping here. Below is the query that would have been executed'
    print, ''
    print, post_str
    return, list()
  endif

  ; set up request
  tic
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.aurorax.space'
  req.setProperty, url_path = 'api/v1/conjunctions/search'
  req.setProperty, headers = ['Content-Type: application/json', 'User-Agent: idl-aurorax/' + __aurorax_version()]

  ; make request
  if (verbose eq 1) then __aurorax_message, 'Sending search request ...'
  r = __aurorax_perform_api_request('post', 'aurorax_conjunction_search', req, post_str = post_str, /expect_empty)

  ; get status code and get response headers
  r.req.getProperty, response_code = status_code, response_header = response_headers

  ; cleanup this request
  obj_destroy, req

  ; check status code
  if (status_code ne 202) then begin
    if (verbose eq 1) then __aurorax_message, 'Error submitting search request: ' + r.output
    return, list()
  endif
  if (verbose eq 1) then __aurorax_message, 'Search request accepted'

  ; set request ID from response headers
  request_id = __aurorax_extract_request_id_from_response_headers(response_headers, 65)
  if (request_id eq '') then begin
    return, list()
  endif
  if (verbose eq 1) then __aurorax_message, 'Request ID: ' + request_id

  ; wait for request to be done
  status = __aurorax_request_wait_for_data('conjunctions', request_id, poll_interval, verbose, print_header = 'aurorax_conjunction_search')
  if (verbose eq 1) then __aurorax_message, 'Data is now available'

  ; humanize size of data to download
  if (verbose eq 1) then begin
    if (keyword_set(response_format)) then begin
      __aurorax_message, 'Downloading up to ' + __aurorax_humanize_bytes(status.search_result.file_size) + ' of data ...'
    endif else begin
      __aurorax_message, 'Downloading ' + __aurorax_humanize_bytes(status.search_result.file_size) + ' of data ...'
    endelse
  endif

  ; get data
  response = __aurorax_request_get_data('conjunctions', request_id, response_format = response_format, print_header = 'aurorax_conjunction_search')
  if (response eq !null) then return, !null
  if (verbose eq 1) then __aurorax_message, 'Data downloaded, search completed'

  ; post-process data (ie. change 'start' to 'start_ts', and '_end' to 'end_ts')
  if (verbose eq 1) then begin
    if (keyword_set(response_format)) then begin
      __aurorax_message, 'Post-processing data into hash'
    endif else begin
      __aurorax_message, 'Post-processing data into struct'
    endelse
  endif
  data_adjusted = list()
  if (keyword_set(response_format)) then begin
    ; response format specified, so we return a hash instead
    response = hash(response, /lowercase, /extract)
  endif else begin
    for i = 0, n_elements(response.data) - 1 do begin
      events_adjusted = list()
      if (n_elements(response.data[i].events) gt 0) then begin
        for j = 0, n_elements(response.data[i].events) - 1 do begin
          new_event_struct = { $
            e1_source: response.data[i].events[j].e1_source, $
            e2_source: response.data[i].events[j].e2_source, $
            start_ts: response.data[i].events[j].start, $
            end_ts: response.data[i].events[j]._end, $
            min_distance: response.data[i].events[j].min_distance, $
            max_distance: response.data[i].events[j].max_distance}
          events_adjusted.add, new_event_struct
        endfor
      endif
      new_record_struct = { $
        start_ts: response.data[i].start, $
        end_ts: response.data[i]._end, $
        min_distance: response.data[i].min_distance, $
        max_distance: response.data[i].max_distance, $
        closest_epoch: response.data[i].closest_epoch, $
        farthest_epoch: response.data[i].farthest_epoch, $
        data_sources: response.data[i].data_sources, $
        events: events_adjusted}
      data_adjusted.add, new_record_struct
    endfor
    response.data = data_adjusted
  endelse

  ; get elapsed time
  toc_ts = toc()
  duration_str = __aurorax_time2string(toc_ts)

  ; return
  if (verbose eq 1) then __aurorax_message, 'Search completed, found ' + strtrim(status.search_result.result_count, 2) + $
    ' conjunctions in ' + duration_str
  return, response
end

;+
; :Description:
;       Describe a conjunction search query.
;
;       This function returns the description string for the conjunction search.
;
; :Parameters:
;       start_ts: in, required, String
;         start datetime, string (different formats allowed, see above)
;       end_ts: in, required, String
;         end datetime, string (different formats allowed, see above)
;       distance: in, required, Integer or Hash
;         max distance between criteria blocks, integer or hash
;
; :Keywords:
;       ground: in, optional, List
;         ground criteria blocks
;       space: in, optional, List
;         space criteria blocks
;       events: in, optional, List
;         events criteria blocks
;       custom_locations: in, optional, List
;         custom locations criteria blocks
;       nbtrace: in, optional, Boolean
;         search for north B-trace conjunctions
;       sbtrace: in, optional, Boolean
;         search for south B-trace conjunctions
;       geographic: in, optional, Boolean
;         search for geographic conjunctions
;
; :Returns:
;       String
;
; :Examples:
;       ; simple example
;       distance = 500
;       start_ts = '2019-01-01T00:00:00'
;       end_ts = '2019-01-03T23:59:59'
;       ground = list(aurorax_create_criteria_block(programs=['themis-asi'],platforms=['fort smith', 'gillam'],/GROUND))
;       space = list(aurorax_create_criteria_block(programs=['swarm'],hemisphere=['northern'],/SPACE))
;       response = aurorax_conjunction_describe(start_ts,end_ts,distance,ground=ground,space=space,/nbtrace)
;+
function aurorax_conjunction_describe, $
  start_ts, $
  end_ts, $
  distance, $
  ground = ground, $
  space = space, $
  events = events, $
  custom_locations = custom_locations, $
  nbtrace = ct_nbtrace, $
  sbtrace = ct_sbtrace, $
  geographic = ct_geo
  ; init
  verbose = 0

  ; construct post structure
  post_str = __aurorax_conjunctions_create_post_str(verbose, $
    start_ts, $
    end_ts, $
    distance, $
    ct_nbtrace, $
    ct_sbtrace, $
    ct_geo, $
    ground, $
    space, $
    events, $
    custom_locations)

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.aurorax.space'
  req.setProperty, url_path = 'api/v1/utils/describe/query/conjunction'
  req.setProperty, headers = ['Content-Type: application/json', 'User-Agent: idl-aurorax/' + __aurorax_version()]

  ; make request
  r = __aurorax_perform_api_request('post', 'aurorax_conjunction_describe', req, post_str = post_str)
  if (r.status_code ne 200) then return, !null
  output = r.output

  ; cleanup this request
  obj_destroy, req

  ; return
  return, output
end
