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

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_EPHEMERIS_SEARCH
;
; PURPOSE:
;       Retrieve AuroraX ephemeris records
;
; EXPLANATION:
;       Retrieve ephemeris records from the AuroraX platform, with optional
;       parameters used to filter for specific matching data.
;
; CALLING SEQUENCE:
;       aurorax_ephemeris_search(start_dt, end_dt)
;
; PARAMETERS:
;       start_dt           start datetime, string (different formats allowed, see below)
;       end_dt             end datetime, string (different formats allowed, see below)
;       programs           programs to filter for, list(string), optional
;       platforms          platforms to filter for, list(string), optional
;       instrument_types   instrument types to filter for, list(string), optional
;       metadata_filters   metadata filters to filter for, hash, optional
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
;       /QUIET           quiet output when searching, no print messages will be shown
;       /DRYRUN          run in dry-run mode, which will exit before sending the search
;                        request to AuroraX. The query will be printed though, so that
;                        users can check to make sure it would have sent the request
;                        that they wanted it to send.
;
; OUTPUT:
;       the found ephemeris records
;
; OUTPUT TYPE:
;       a search response struct
;
; EXAMPLES:
;       ; simple example
;       response = aurorax_ephemeris_search('2020-01-01T00:00','2020-01-01T23:59',programs=['swarm'],platforms=['swarma'],instrument_types=['footprint'])
;
;       ; example with metadata
;       expression = aurorax_create_metadata_filter_expression('nbtrace_region', list('north auroral oval', 'north mid-latitude'),/OPERATOR_IN)
;       expressions = list(expression)
;       metadata_filters = aurorax_create_metadata_filter(expressions,/OPERATOR_AND)
;       response = aurorax_ephemeris_search('2020-01-01T00:00','2020-01-01T23:59',programs=['swarm'],metadata_filters=metadata_filters)
;+
;-------------------------------------------------------------
function aurorax_ephemeris_search,start_dt,end_dt,programs=programs,platforms=platforms,instrument_types=instrument_types,metadata_filters=metadata_filters,poll_interval=pi,QUIET=q,DRYRUN=dr
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

  ; create data sources struct
  if (verbose eq 1) then __aurorax_message,'Creating request struct'
  data_sources_struct = {programs: list(), platforms: list(), instrument_types: list(), ephemeris_metadata_filters: hash()}
  if (isa(programs) eq 1) then data_sources_struct.programs = list(programs,/extract)
  if (isa(platforms) eq 1) then data_sources_struct.platforms = list(platforms,/extract)
  if (isa(instrument_types) eq 1) then data_sources_struct.instrument_types = list(instrument_types,/extract)
  if (isa(metadata_filters) eq 1) then data_sources_struct.ephemeris_metadata_filters = hash(metadata_filters)

  ; create post struct and serialize into a string
  post_struct = {data_sources: data_sources_struct, start: start_iso_dt, end_dt: end_iso_dt}
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
  req->SetProperty,URL_PATH = 'api/v1/ephemeris/search'
  req->SetProperty,HEADERS = ['Content-Type: application/json', 'User-Agent: idl-aurorax/' + __aurorax_version()]

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
  request_id = __aurorax_extract_request_id_from_response_headers(response_headers,62)
  if (request_id eq '') then begin
    return,list()
  endif
  if (verbose eq 1) then __aurorax_message,'Request ID: ' + request_id

  ; wait for request to be done
  status = __aurorax_request_wait_for_data('ephemeris',request_id,poll_interval,verbose)
  if (verbose eq 1) then __aurorax_message,'Data is now available'

  ; humanize size of data to download
  bytes_str = __aurorax_humanize_bytes(status.search_result.file_size)
  if (verbose eq 1) then __aurorax_message,'Downloading ' + __aurorax_humanize_bytes(status.search_result.file_size) + ' of data ...'

  ; get data
  data = __aurorax_request_get_data('ephemeris',request_id)
  if (verbose eq 1) then __aurorax_message,'Data downloaded, search completed'

  ; get elapsed time
  toc_ts = toc()
  duration_str = __aurorax_time2string(toc_ts)

  ; return
  if (verbose eq 1) then __aurorax_message,'Search completed, found ' + strtrim(status.search_result.result_count,2) + ' records in ' + duration_str
  return,data
end
