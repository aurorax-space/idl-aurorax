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

; definition for metadata filters

;;;;;;;;

function __aurorax_request_get_status,request_type,request_id
  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.aurorax.space'
  req->SetProperty,URL_PATH = 'api/v1/' + request_type + '/requests/' + request_id

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; serialize into struct
  status = json_parse(output,/TOSTRUCT)

  ; return
  return,status
end

function __aurorax_request_wait_for_data,request_type,request_id,poll_interval,verbose
  while (1) do begin
    ; get status
    if (verbose eq 1) then __aurorax_message,'Waiting for search to finish ...'
    status = __aurorax_request_get_status(request_type, request_id)

    ; check status to see if request has completed
    if (strpos(status.search_result.completed_timestamp,'!NULL') ne 0) then begin
      ; data is available, bail out
      break
    endif

    ; wait
    wait,poll_interval
  endwhile

  ; return completed status
  return,status
end

function __aurorax_request_get_data,request_type,request_id
  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.aurorax.space'
  req->SetProperty,URL_PATH = 'api/v1/' + request_type + '/requests/' + request_id + '/data'

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; serialize into struct
  data = json_parse(output,/TOSTRUCT)
  data = data.result

  ; return
  return,data
end

function aurorax_ephemeris_search,start_dt,end_dt,programs=programs,platforms=platforms,instrument_types=instrument_types,metadata_filters=metadata_filters,poll_interval=pi,quiet=q
  ; set verbosity
  verbose = 1
  if (isa(q) eq 1) then verbose = 0

  ; set up some other vars we'll use
  expected_url_length = 20

  ; set poll interval
  poll_interval = 1
  if (isa(pi) eq 1) then poll_interval = pi

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
  if (isa(metadata_filters) eq 1) then data_sources_struct.metadata_filters = metadata_filters

  ; create post struct and serialize into a string
  post_struct = {data_sources: data_sources_struct, start: start_iso_dt, end_dt: end_iso_dt}
  post_str = json_serialize(post_struct,/lowercase)
  post_str = post_str.replace('end_dt','end')  ; because 'end' isn't a valid struct tag name
  ;print,post_str

  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.aurorax.space'
  req->SetProperty,URL_PATH = 'api/v1/ephemeris/search'
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

  ; return
  return,data
end
