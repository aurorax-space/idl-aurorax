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
    status = __aurorax_request_get_status(request_type, request_id)

    ; check status to see if request has completed
    if (strpos(status.search_result.completed_timestamp,'!NULL') ne 0) then begin
      ; data is available, bail out
      break
    endif

    ; wait
    if (verbose eq 1) then __aurorax_message,'Waiting for search to finish ...'
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
  response = {request_type: request_type, request_id: request_id, data: data}

  ; return
  return,response
end
