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

;+
; :Description:
;       Search for data product records in the AuroraX Search Engine,
;       with optional parameters used to filter for specific matching
;       data.
;
;       This function returns the found data product records, as a search
;       response struct

;
;       The 'start_ts' and 'end_ts' parameters are to be timestamps in a
;       variety of formats. The following are examples of what is allowed:
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
;
; :Parameters:
;       start_ts: in, required, String
;         start datetime, string (different formats allowed, see above)
;       end_ts: in, required, String
;         end datetime, string (different formats allowed, see above)
;
; :Keywords:
;       programs: in, optional, List
;         programs to filter for
;       platforms: in, optional, List
;         platforms to filter for
;       instrument_types: in, optional, List
;         instrument types to filter for
;       data_product_types: in, optional, List
;         data product types to filter for
;       metadata_filters: in, optional, Hash
;         metadata filters to filter for
;       poll_interval: in, optional, Integer
;         sleep time between polling events while waiting for data (in seconds; default is 1s)
;       quiet: in, optional, Boolean
;         quiet output when searching, no print messages will be shown
;       dryrun: in, optional, Boolean
;         run in dry-run mode, which will exit before sending the search
;         request to AuroraX. The query will be printed though, so that
;         users can check to make sure it would have sent the request
;         that they wanted it to send.
;
; :Returns:
;       Struct
;
; :Examples:
;       ; simple example
;       response = aurorax_data_product_search('2020-01-01T00:00','2020-01-01T23:59',programs=['trex'],platforms=['gillam'],instrument_types=['RGB ASI'])
;
;       ; example with metadata
;       expression = aurorax_create_metadata_filter_expression('keogram_type', list('daily'),/OPERATOR_IN)
;       expressions = list(expression)
;       metadata_filters = aurorax_create_metadata_filter(expressions,/OPERATOR_AND)
;       response = aurorax_data_product_search('2020-01-01T00:00','2020-01-01T23:59',programs=['trex'],metadata_filters=metadata_filters)
;+
function aurorax_data_product_search, start_ts, $
  end_ts, programs = programs, $
  platforms = platforms, $
  instrument_types = instrument_types, $
  data_product_types = data_product_types, $
  metadata_filters = metadata_filters, $
  poll_interval = pi, $
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

  ; get ISO datetime strings
  if (verbose eq 1) then __aurorax_message, 'Parsing start and end timestamps'
  start_iso_dt = __aurorax_datetime_parser(start_ts, /interpret_as_start)
  end_iso_dt = __aurorax_datetime_parser(end_ts, /interpret_as_end)
  if (start_iso_dt eq '' or end_iso_dt eq '') then return, list()

  ; create data sources struct
  if (verbose eq 1) then __aurorax_message, 'Creating request struct'
  data_sources_struct = {programs: list(), platforms: list(), instrument_types: list(), data_product_metadata_filters: hash()}
  if (isa(programs) eq 1) then data_sources_struct.programs = list(programs, /extract)
  if (isa(platforms) eq 1) then data_sources_struct.platforms = list(platforms, /extract)
  if (isa(instrument_types) eq 1) then data_sources_struct.instrument_types = list(instrument_types, /extract)
  if (isa(metadata_filters) eq 1) then data_sources_struct.data_product_metadata_filters = hash(metadata_filters)

  ; create post struct and serialize into a string
  post_struct = {data_sources: data_sources_struct, start: start_iso_dt, end_ts: end_iso_dt, data_product_type_filters: list()}
  if (isa(data_product_types) eq 1) then data_sources_struct.data_product_type_filters = list(data_product_types, /extract)
  post_str = json_serialize(post_struct, /lowercase)
  post_str = post_str.replace('LOGICAL_OPERATOR', 'logical_operator') ; because of a bug in json_serialize where it doesn't lowercase nested hashes
  post_str = post_str.replace('EXPRESSIONS', 'expressions') ; because of a bug in json_serialize where it doesn't lowercase nested hashes
  post_str = post_str.replace('end_ts', 'end') ; because 'end' isn't a valid struct tag name

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
  req.setProperty, url_path = 'api/v1/data_products/search'
  req.setProperty, headers = ['Content-Type: application/json', 'User-Agent: idl-aurorax/' + __aurorax_version()]

  ; make request
  if (verbose eq 1) then __aurorax_message, 'Sending search request ...'
  output = req.put(post_str, /buffer, /string_array, /post)

  ; get status code and get response headers
  req.getProperty, response_code = status_code, response_header = response_headers

  ; cleanup this request
  obj_destroy, req

  ; check status code
  if (status_code ne 202) then begin
    if (verbose eq 1) then __aurorax_message, 'Error submitting search request: ' + output
    return, list()
  endif
  if (verbose eq 1) then __aurorax_message, 'Search request accepted'

  ; set request ID from response headers
  request_id = __aurorax_extract_request_id_from_response_headers(response_headers, 66)
  if (request_id eq '') then begin
    return, list()
  endif
  if (verbose eq 1) then __aurorax_message, 'Request ID: ' + request_id

  ; wait for request to be done
  status = __aurorax_request_wait_for_data('data_products', request_id, poll_interval, verbose)
  if (verbose eq 1) then __aurorax_message, 'Data is now available'

  ; humanize size of data to download
  if (verbose eq 1) then __aurorax_message, 'Downloading ' + __aurorax_humanize_bytes(status.search_result.file_size) + ' of data ...'

  ; get data
  response = __aurorax_request_get_data('data_products', request_id)
  if (verbose eq 1) then __aurorax_message, 'Data downloaded, search completed'

  ; post-process data (ie. change 'start' to 'start_ts', and '_end' to 'end_ts')
  if (verbose eq 1) then __aurorax_message, 'Post-processing data into IDL struct'
  data_adjusted = list()
  for i = 0, n_elements(response.data) - 1 do begin
    new_record_struct = {start_ts: response.data[i].start, end_ts: response.data[i]._end, data_source: response.data[i].data_source, url: response.data[i].url, data_product_type: response.data[i].data_product_type, metadata: response.data[i].metadata}
    data_adjusted.add, new_record_struct
  endfor
  response.data = data_adjusted

  ; get elapsed time
  toc_ts = toc()
  duration_str = __aurorax_time2string(toc_ts)

  ; return
  if (verbose eq 1) then __aurorax_message, 'Search completed, found ' + strtrim(status.search_result.result_count, 2) + ' records in ' + duration_str
  return, response
end
