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

function __aurorax_request_get_status, request_type, request_id
  compile_opt hidden

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.aurorax.space'
  req.setProperty, url_path = 'api/v1/' + request_type + '/requests/' + request_id
  req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req.get(/string_array)

  ; serialize into struct
  status = json_parse(output, /tostruct)

  ; return
  return, status
end

function __aurorax_request_wait_for_data, request_type, request_id, poll_interval, verbose
  compile_opt hidden

  while (1) do begin
    ; get status
    status = __aurorax_request_get_status(request_type, request_id)

    ; check status to see if request has completed
    if (strpos(status.search_result.completed_timestamp, '!NULL') ne 0) then begin
      ; data is available, bail out
      break
    endif

    ; wait
    if (verbose eq 1) then __aurorax_message, 'Waiting for search to finish ...'
    wait, poll_interval
  endwhile

  ; return completed status
  return, status
end

function __aurorax_request_get_data, request_type, request_id
  compile_opt hidden

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.aurorax.space'
  req.setProperty, url_path = 'api/v1/' + request_type + '/requests/' + request_id + '/data'
  req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req.get(/string_array)

  ; serialize into struct
  data = json_parse(output, /tostruct)
  data = data.result
  response = {request_type: request_type, request_id: request_id, data: data}

  ; return
  return, response
end
