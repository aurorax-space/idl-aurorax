;-------------------------------------------------------------
; MIT License
;
; Copyright (c) 2022 University of Calgary
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;-------------------------------------------------------------

function __aurorax_derive_advanced_distances,ground_count=ground_count,space_count=space_count,events_count=events_count
  ; initialize values that aren't entered
  if (isa(ground_count) eq 0) then ground_count = 0
  if (isa(space_count) eq 0) then space_count = 0
  if (isa(events_count) eq 0) then events_count = 0

  ; check to make sure there's two or more
  if (ground_count + space_count + events_count lt 2) then begin
    print,'Error generating distance mappings: must have 2 or more total count'
    return,hash()
  endif

  ; set input arrays
  options = list()
  for i=1,ground_count do begin
    options.add,'ground' + strtrim(i,2)
  endfor
  for i=1,space_count do begin
    options.add,'space' + strtrim(i,2)
  endfor
  for i=1,events_count do begin
    options.add,'events' + strtrim(i,2)
  endfor

  ; derive all combinations of options of size 2
  combinations = list()
  for i=0,n_elements(options)-1 do begin
    for j=0,n_elements(options)-1 do begin
      if (i ne j) then begin
        combo = options[i] + '-' + options[j]
        combo_reversed = options[j] + '-' + options[i]
        if (combinations.where(combo) eq !NULL and combinations.where(combo_reversed) eq !NULL) then begin
          ; not already in the list, add it
          combinations.add,combo
        endif
      endif
    endfor
  endfor

  ; return
  return,combinations
end

function __aurorax_validate_advanced_distances,distance,ground_count=ground_count,space_count=space_count,events_count=events_count
  ; initialize values that aren't entered
  if (isa(ground_count) eq 0) then ground_count = 0
  if (isa(space_count) eq 0) then space_count = 0
  if (isa(events_count) eq 0) then events_count = 0

  ; get expected pairings
  expected_pairings = __aurorax_derive_advanced_distances(ground_count=ground_count,space_count=space_count,events_count=events_count)

  ; cross-check expected pairings with what was supplied
  supplied_keys = distance.keys()
  for i=0,n_elements(expected_pairings)-1 do begin
    if (supplied_keys.where(expected_pairings[i]) eq !NULL) then begin
      ; found an expected pair that was not included in the supplied distances hash, throw error
      print,"Error: distances hash does not have all expected pairings, missing '" + expected_pairings[i] + "'"
      return,0
    endif
  endfor

  ; is valid
  return,1
end

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_CREATE_ADVANCED_DISTANCES_HASH
;
; PURPOSE:
;       Create advanced distances pairing for a conjunction search
;
; EXPLANATION:
;       The AuroraX conjunction search requires distance pairings for every
;       possibility of criteria blocks. This function will generate all
;       possibilities for you.
;
; CALLING SEQUENCE:
;       aurorax_create_advanced_distances_hash(distance)
;
; PARAMETERS:
;       distance           default distance for each pairing, integer
;       ground_count       number of ground criteria blocks, integer, optional
;       space_count        number of space criteria blocks, integer, optional
;       events_count       number of events criteria blocks, integer, optional
;
; OUTPUT:
;       the advanced distances
;
; OUTPUT TYPE:
;       a hash, with the default value for each value being the 'distance' variable supplied
;
; EXAMPLES:
;       distances = aurorax_create_advanced_distances_hash(500, ground_count=1, space_count=2)
;
; REVISION HISTORY:
;   - Initial implementation, Feb 2022, Darren Chaddock
;+
;-------------------------------------------------------------
function aurorax_create_advanced_distances_hash,distance,ground_count=ground_count,space_count=space_count,events_count=events_count
  ; initialize values that aren't entered
  if (isa(ground_count) eq 0) then ground_count = 0
  if (isa(space_count) eq 0) then space_count = 0
  if (isa(events_count) eq 0) then events_count = 0

  ; get pairings
  keys = __aurorax_derive_advanced_distances(ground_count=ground_count,space_count=space_count,events_count=events_count)

  ; create hash object
  values = intarr(n_elements(keys))
  for i=0,n_elements(values)-1 do begin
    values[i] = distance
  endfor
  distances = hash(keys, values)

  ; return
  return,distances
end

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_CONJUNCTION_SEARCH
;
; PURPOSE:
;       Search AuroraX for conjunctions
;
; EXPLANATION:
;       Search the AuroraX platform for conjunctions using the supplied
;       filter criteria
;
; CALLING SEQUENCE:
;       aurorax_conjunction_search(start_dt, end_dt, distance)
;
; PARAMETERS:
;       start_dt           start datetime, string (different formats allowed, see below)
;       end_dt             end datetime, string (different formats allowed, see below)
;       distance           max distance between criteria blocks, integer or hash (different
;                          formats allowed, see below)
;       ground             ground criteria blocks, list, optional
;       space              space criteria blocks, list, optional
;       events             events criteria blocks, list, optional
;       poll_interval      sleep time between polling events while waiting for data, integer,
;                          optional (in seconds; default is 1s)
;
;       The 'start_dt' and 'end_dt' parameters are to be timestamps in a variety of formats. The
;       following are examples of what is allowed:
;
;       The following are all interpreted as '2020-01-01T00:00:00':
;         start_dt = '2020'
;         start_dt = '202001'
;         start_dt = '20200101'
;         start_dt = '2020010100'
;         start_dt = '202001010000'
;         start_dt = '2020-01-01'
;         start_dt = '2020/01/01T00:00'
;         start_dt = '2020-01-01 00:00'
;
;       The following are all interpreted as '2020-12-31T23:59:59':
;         end_dt = '2020'
;         end_dt = '202012'
;         end_dt = '20201231'
;         end_dt = '2020123123'
;         end_dt = '202012312359'
;         end_dt = '2020-12-31'
;         end_dt = '2020/12/31T23'
;         end_dt = '2020-12-31 23'
;
; KEYWORDS:
;       /NBTRACE         search for nbtrace conjunctions
;       /SBTRACE         search for sbtrace conjunctions
;       /GEOGRAPHIC      search for geographic conjunctions
;       /QUIET           quiet output when searching, no print messages will be shown
;       /DRYRUN          run in dry-run mode, which will exit before sending the search
;                        request to AuroraX. The query will be printed though, so that
;                        users can check to make sure it would have sent the request
;                        that they wanted it to send.
;
; OUTPUT:
;       the found conjunctions
;
; OUTPUT TYPE:
;       a search response struct
;
; EXAMPLES:
;       ; simple example
;       distance = 500
;       start_dt = '2019-01-01T00:00:00'
;       end_dt = '2019-01-03T23:59:59'
;       ground1 = aurorax_create_criteria_block(programs=['themis-asi'],platforms=['fort smith', 'gillam'],/GROUND)
;       ground = list(ground1)
;       space1 = aurorax_create_criteria_block(programs=['swarm'],hemisphere=['northern'],/SPACE)
;       space = list(space1)
;       response = aurorax_conjunction_search(start_dt,end_dt,distance,ground=ground,space=space,/nbtrace)
;
;       ; example with metadata
;       distance = 500
;       start_dt = '2008-01-01T00:00:00'
;       end_dt = '2008-01-31T23:59:59'
;       expression1 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1', list('classified as APA'),/OPERATOR_IN)
;       expression2 = aurorax_create_metadata_filter_expression('calgary_apa_ml_v1_confidence', 95,/OPERATOR_GE)
;       expressions = list(expression1, expression2)
;       ground_metadata_filters = aurorax_create_metadata_filter(expressions,/OPERATOR_AND)
;       ground1 = aurorax_create_criteria_block(programs=['themis-asi'],metadata_filters=ground_metadata_filters,/GROUND)
;       ground = list(ground1)
;       space1 = aurorax_create_criteria_block(programs=['themis'],hemisphere=['northern'],/SPACE)
;       space = list(space1)
;       response = aurorax_conjunction_search(start_dt,end_dt,distance,ground=ground,space=space,/nbtrace)
;+
;-------------------------------------------------------------
function aurorax_conjunction_search,start_dt,end_dt,distance,ground=ground,space=space,events=events,poll_interval=pi,NBTRACE=ct_nbtrace,SBTRACE=ct_sbtrace,GEOGRAPHIC=ct_geo,QUIET=q,DRYRUN=dr
  ; set verbosity
  verbose = 1
  if (isa(q) eq 1) then verbose = 0

  ; set poll interval
  poll_interval = 1
  if (isa(pi) eq 1) then poll_interval = pi

  ; set dry run flag
  dry_run = 0
  if (isa(dr) eq 1) then dry_run = 1
  if (verbose eq 1 and dry_run eq 1) then __aurorax_message,'Executing in dry-run mode'

  ; get ISO datetime strings
  if (verbose eq 1) then __aurorax_message,'Parsing start and end timestamps'
  start_iso_dt = __aurorax_datetime_parser(start_dt,/interpret_as_start)
  end_iso_dt = __aurorax_datetime_parser(end_dt,/interpret_as_end)
  if (start_iso_dt eq '' or end_iso_dt eq '') then return,list()

  ; check criteria block count validity
  criteria_block_count = n_elements(ground) + n_elements(space) + n_elements(events)
  if (criteria_block_count gt 10) then begin
    __aurorax_message,'Error: too many criteria blocks, max of 10 is allowed and ' + strtrim(criteria_block_count,2) + ' have been supplied. Please reduce the count and try again.'
    return,list()
  endif

  ; set distance
  if (isa(distance,/integer) eq 1 or isa(distance,/float) eq 1) then begin
    ; entered distance is a single number, use that to generate all the max distance pairings
    distances_hash = aurorax_create_advanced_distances_hash(distance, ground_count=n_elements(ground), space_count=n_elements(space), events_count=n_elements(events))
  endif else if (isa(distance,'HASH') eq 1) then begin
    ; entered distance is the correct object type, make sure it has all the correct pairings
    distances_valid = __aurorax_validate_advanced_distances(distance, ground_count=n_elements(ground), space_count=n_elements(space), events_count=n_elements(events))
    if (distances_valid eq 1) then begin
      distances_hash = distance
    endif else begin
      __aurorax_message,'Error: distances object is not valid, update your distances object and try again (in most cases, the object is missing pairings)'
      return,list()
    endelse
  endif

  ; set conjunction types
  conjunction_types = list()
  if keyword_set(ct_nbtrace) then conjunction_types.add,'nbtrace'
  if keyword_set(ct_sbtrace) then conjunction_types.add,'sbtrace'
  if keyword_set(ct_geo) then conjunction_types.add,'geographic'

  ; create data sources struct
  if (verbose eq 1) then __aurorax_message,'Creating request struct'
  post_struct = {start: start_iso_dt, end_dt: end_iso_dt, ground: list(), space: list(), events: list(), conjunction_types: list(), max_distances: distances_hash}
  if (isa(ground) eq 1) then post_struct.ground = ground
  if (isa(space) eq 1) then post_struct.space = space
  if (isa(events) eq 1) then post_struct.events = events
  post_struct.conjunction_types = conjunction_types
  post_struct.max_distances = distances_hash

  ; serialize into a string
  post_str = json_serialize(post_struct,/lowercase)
  post_str = post_str.replace('LOGICAL_OPERATOR', 'logical_operator')  ; because of a bug in json_serialize where it doesn't lowercase nested hashes
  post_str = post_str.replace('EXPRESSIONS', 'expressions')            ; because of a bug in json_serialize where it doesn't lowercase nested hashes
  post_str = post_str.replace('end_dt','end')                          ; because 'end' isn't a valid struct tag name

  ; stop here if in dry-run mode
  if (dry_run eq 1) then begin
    __aurorax_message,'Dry-run mode, stopping here. Below is the query that would have been executed'
    print,''
    print,post_str
    return,list()
  endif

  ; set up request
  tic
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.aurorax.space'
  req->SetProperty,URL_PATH = 'api/v1/conjunctions/search'
  req->SetProperty,HEADERS = 'Content-Type: application/json'

  ; make request
  if (verbose eq 1) then __aurorax_message,'Sending search request ...'
  output = req->Put(post_str, /BUFFER, /STRING_ARRAY, /POST)

  ; get status code and get response headers
  req->GetProperty,RESPONSE_CODE=status_code,RESPONSE_HEADER=response_headers

  ; cleanup this request
  obj_destroy,req

  ; check status code
  if (status_code ne 202) then begin
    if (verbose eq 1) then __aurorax_message,'Error submitting search request: ' + output
    return,list()
  endif
  if (verbose eq 1) then __aurorax_message,'Search request accepted'

  ; set request ID from response headers
  request_id = __aurorax_extract_request_id_from_response_headers(response_headers,65)
  if (request_id eq '') then begin
    return,list()
  endif
  if (verbose eq 1) then __aurorax_message,'Request ID: ' + request_id

  ; wait for request to be done
  status = __aurorax_request_wait_for_data('conjunctions',request_id,poll_interval,verbose)
  if (verbose eq 1) then __aurorax_message,'Data is now available'

  ; humanize size of data to download
  bytes_str = __aurorax_humanize_bytes(status.search_result.file_size)
  if (verbose eq 1) then __aurorax_message,'Downloading ' + __aurorax_humanize_bytes(status.search_result.file_size) + ' of data ...'

  ; get data
  response = __aurorax_request_get_data('conjunctions',request_id)
  if (verbose eq 1) then __aurorax_message,'Data downloaded, search completed'

  ; post-process data (ie. change 'start' to 'start_dt', and '_end' to 'end_dt')
  if (verbose eq 1) then __aurorax_message,'Post-processing data into IDL struct'
  data_adjusted = list()
  for i=0,n_elements(response.data)-1 do begin
    events_adjusted = list()
    if (n_elements(response.data[i].events) gt 0) then begin
      for j=0,n_elements(response.data[i].events)-1 do begin
        new_event_struct = {e1_source: response.data[i].events[j].e1_source, e2_source: response.data[i].events[j].e2_source, start_dt: response.data[i].events[j].start, end_dt: response.data[i].events[j]._end, min_distance: response.data[i].events[j].min_distance, max_distance: response.data[i].events[j].max_distance}
        events_adjusted.add,new_event_struct
      endfor
    endif
    new_record_struct = {start_dt: response.data[i].start, end_dt: response.data[i]._end, min_distance: response.data[i].min_distance, max_distance: response.data[i].max_distance, closest_epoch: response.data[i].closest_epoch, farthest_epoch: response.data[i].farthest_epoch, data_sources: response.data[i].data_sources, events: events_adjusted}
    data_adjusted.add,new_record_struct
  endfor
  response.data = data_adjusted

  ; get elapsed time
  toc_ts = toc()
  duration_str = __aurorax_time2string(toc_ts)

  ; return
  if (verbose eq 1) then __aurorax_message,'Search completed, found ' + strtrim(status.search_result.result_count,2) + ' conjunctions in ' + duration_str
  return,response
end