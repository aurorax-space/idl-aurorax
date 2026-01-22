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

function __generate_random_api_request_filename
  ; num chars
  num_chars = 8

  ; generate random numbers (uppercase A-Z, 0-9), which will later be converted into chars
  random_values = fix(randomu(!null, num_chars) * 36) ; Generate random numbers (0-35, total of possible numbers+chars)

  ; convert numbers to alphanumeric characters
  random_chars = ''
  for i = 0, num_chars - 1 do begin
    char_index = random_values[i]
    if (char_index lt 10) then begin
      ; digits 0-9
      random_chars += string(char_index, format = '(I1)')
    endif else begin
      ; letters A-Z (charIndex 10-35 maps to ASCII 65-90)
      random_chars += string(byte(65 + (char_index - 10)))
    endelse
  endfor

  ; concatenate final filename
  filename = getenv('IDL_TMPDIR') + 'idlaurorax_api_request_' + random_chars + '.dat'

  ; return
  return, filename
end

function __aurorax_perform_api_request, request_type, print_header, req, post_str = post_str, expect_empty = expect_empty
  ; set proxy
  proxy_hostname = getenv('AURORAX_PROXY_HOSTNAME')
  proxy_port = getenv('AURORAX_PROXY_PORT')
  if (proxy_hostname ne '' and proxy_port ne '') then begin
    ; proxy hostname and port are configured, set them in the request object
    req.setProperty, proxy_host = proxy_hostname
    req.setProperty, proxy_port = fix(proxy_port)

    ; set username and password
    proxy_username = getenv('AURORAX_PROXY_USERNAME')
    proxy_password = getenv('AURORAX_PROXY_PASSWORD')
    if (proxy_username ne '') then req.setProperty, proxy_username = proxy_username
    if (proxy_password ne '') then req.setProperty, proxy_password = proxy_password
  endif

  ; set temp filename
  temp_filename = __generate_random_api_request_filename()

  ; check for error
  catch, error_status
  if (error_status ne 0) then begin
    catch, /cancel
    req.getProperty, response_code = response_code
    top_level_error_message = !error_state.msg
    obj_destroy, req

    ; read the response filename contents to extract the error message
    ;
    ; NOTE: we need to check if the file exists first, as the error
    ; could be upstream from an API mandated error, like a timeout
    ; or a bad gateway, etc.
    if (file_test(temp_filename) eq 0 or top_level_error_message ne '') then begin
      ; the error is upstream from the API
      error_message = top_level_error_message
    endif else begin
      openr, lun, temp_filename, /get_lun
      error_message = ''
      line = ''
      while not eof(lun) do begin
        readf, lun, line
        error_message = error_message + line
      endwhile
      free_lun, lun

      ; cleanup
      file_delete, temp_filename, /allow_nonexistent

      ; check if the usual Python API error message format exists, if so, then use it
      if (strpos(error_message, '"detail":') ne -1) then begin
        error_message = json_parse(error_message)
        error_message = error_message['detail']
      endif
    endelse

    ; evaluate error code
    print, '[' + print_header + '] Error performing request'
    print, '  API status code: ' + string(response_code, format = '(I0)')
    print, '  API error message: ' + error_message.toString()

    ; bail out
    return, {req: req, output: '', error_message: error_message, status_code: response_code}
  endif

  ; make request
  if (request_type eq 'post') then begin
    output = req.put(post_str, /buffer, /post, filename = temp_filename)
  endif else if (request_type eq 'get') then begin
    output = req.get(filename = temp_filename)
  endif

  ; extract status code
  req.getProperty, response_code = response_code

  ; read output
  output = ''
  if (not keyword_set(expect_empty)) then begin
    ; we don't expect an empty response, so we need to read it from
    ; the temp filename
    openr, lun, temp_filename, /get_lun
    output = ''
    line = ''
    while not eof(lun) do begin
      readf, lun, line
      output = output + line
    endwhile
    free_lun, lun
  endif

  ; cleanup
  file_delete, temp_filename, /allow_nonexistent

  ; return
  return, {req: req, output: output, error_message: '', status_code: response_code}
end

function __aurorax_request_get_status, request_type, request_id, print_header = print_header
  compile_opt hidden

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.aurorax.space'
  req.setProperty, url_path = 'api/v1/' + request_type + '/requests/' + request_id
  req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  r = __aurorax_perform_api_request('get', print_header, req)
  if (r.status_code ne 200) then return, !null
  output = r.output

  ; cleanup this request
  obj_destroy, req

  ; serialize into struct
  status = json_parse(output, /tostruct)

  ; return
  return, status
end

function __aurorax_request_wait_for_data, request_type, request_id, poll_interval, verbose, print_header = print_header
  compile_opt hidden

  while (1) do begin
    ; get status
    status = __aurorax_request_get_status(request_type, request_id, print_header = print_header)

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

function __aurorax_request_get_data, request_type, request_id, response_format = response_format, print_header = print_header
  compile_opt hidden

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.aurorax.space'
  req.setProperty, url_path = 'api/v1/' + request_type + '/requests/' + request_id + '/data'

  ; do request
  if (keyword_set(response_format) and response_format ne !null and n_elements(response_format) ne 0) then begin
    ; is a request that has a response format, so we need to make sure it's in the
    ; correct hash format, and do a post
    ;
    ; make sure the response format is a hash
    if (isa(response_format, 'STRUCT') eq 1) then begin
      ; is a struct, convert to hash
      response_format = hash(response_format, /lowercase)
    endif

    ; set the post string
    post_str = json_serialize(response_format, /lowercase)
    post_str = post_str.replace('start_ts', 'start')
    post_str = post_str.replace('end_ts', 'end') ; because 'end' isn't a valid struct tag name

    ; set the headers
    req.setProperty, headers = ['Content-Type: application/json', 'User-Agent: idl-aurorax/' + __aurorax_version()]

    ; do post
    r = __aurorax_perform_api_request('post', print_header, req, post_str = post_str)

    ; check error condition
    if (r.status_code ne 200) then begin
      ; error occurred, but should have already been handled by the API request catch, so we bail out
      obj_destroy, req
      return, !null
    endif
    output = r.output
  endif else begin
    ; set the headers
    req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

    ; no response format supplied, do a regular get request
    r = __aurorax_perform_api_request('get', 'aurorax_save_swarmaurora_custom_import_file', req)
    if (r.status_code ne 200) then begin
      obj_destroy, req
      return, !null
    endif
    output = r.output
  endelse

  ; clean up request
  obj_destroy, req

  ; serialize into struct, or hash if response format was specified
  if (keyword_set(response_format)) then begin
    output = output.replace('"start":', '"start_ts":')
    output = output.replace('"end":', '"end_ts":')
    data = json_parse(output)
    data = data['result']
  endif else begin
    data = json_parse(output, /tostruct)
    data = data.result
  endelse
  response = {request_type: request_type, request_id: request_id, data: data}

  ; return
  return, response
end
