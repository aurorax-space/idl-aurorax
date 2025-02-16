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
;       Realize a browser window showing conjunction search results
;       in Swarm-Aurora.
;
; :Parameters:
;       request_id: in, required, String
;         the request ID for the conjunction search
;
; :Keywords:
;       xsize: in, optional, Integer
;         specify the width of the browser window rendered, default is 95% of native screen width
;       ysize: in, optional, Integer
;         specify the height of the browser window rendered, default is 90% of native screen height
;       clipboard: in, optional, Boolean
;         copy the Swarm-Aurora URL to the clipboard
;       print_url: in, optional, Boolean
;         instead of rendering a browser window, print out the Swarm-Aurora URL
;
; :Examples:
;       response = aurorax_conjunction_search(start_ts, end_ts, distance, ground=ground, space=space)
;       aurorax_open_conjunctions_in_swarmaurora, response.request_id
;+
pro aurorax_open_conjunctions_in_swarmaurora, request_id, xsize = xsize, ysize = ysize, clipboard = clipboard_kw, print_url = url_kw
  compile_opt idl2

  ; init
  max_conjunctions = 5000
  url = 'https://swarm-aurora.com/conjunctionFinder/?aurorax_request_id=' + request_id

  ; initialize values that aren't entered
  screen_size = get_screen_size()
  if (isa(xsize) eq 0) then xsize = screen_size[0] * 0.95
  if (isa(ysize) eq 0) then ysize = screen_size[1] * 0.9

  ; check that request is finished, and there aren't too many conjuncions
  status = __aurorax_request_get_status('conjunctions', request_id)
  if (isa(status.search_result.result_count) eq 0) then begin
    print, 'Error: this request has not completed yet, please wait and try again'
    return
  endif
  if (status.search_result.result_count ge max_conjunctions) then begin
    print, 'Error: too many conjunctions, reduce the parameters for your search to find less than ' + strtrim(max_conjunctions, 2) + ' conjunctions and try again'
    return
  endif

  ; check keywords
  if keyword_set(url_kw) then begin
    print, 'Swarm-Aurora URL: ' + url
  endif
  if keyword_set(clipboard_kw) then begin
    ; copy URL to clipboard
    Clipboard.set, url
    print, 'Swarm-Aurora URL copied to your clipboard!'
  endif
  if (keyword_set(url_kw) eq 0) and (keyword_set(clipboard_kw) eq 0) then begin
    ; realize the window
    window_parent = widget_base()
    browser = widget_browser(window_parent, value = url, xsize = xsize, ysize = ysize)
    widget_control, window_parent, /realize
  endif
end

;+
; :Description:
;       Download a Swarm-Aurora custom import file
;
;       Retrieve a Swarm-Aurora custom import file for a conjunction
;       search request, and save it to a JSON file.
;
; :Parameters:
;       request_id: in, required, String
;         the request ID for the conjunction search
;
; :Keywords:
;       filename: in, optional, String
;         the filename to save the custom import file to, default is a filename made up
;         from the current working directory of the IDL instance
;
; :Examples:
;       response = aurorax_conjunction_search(start_ts, end_ts, distance, ground=ground, space=space)
;       aurorax_save_swarmaurora_custom_import_file, response.request_id
;+
pro aurorax_save_swarmaurora_custom_import_file, request_id, filename = filename
  compile_opt idl2
  ; set filename
  cd, current = cwd
  if (isa(filename) eq 0) then filename = cwd + '\swarmaurora_custom_import_' + request_id + '.json'

  ; retrieve custom import file contents
  __aurorax_message, 'Retrieving custom import file contents from Swarm-Aurora ...'
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'swarm-aurora.com'
  req.setProperty, url_path = 'conjunctionFinder/generate_custom_import_json'
  req.setProperty, url_query = 'aurorax_request_id=' + request_id
  req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req.get(/string_array)

  ; cleanup
  obj_destroy, req

  ; write to file
  __aurorax_message, 'Writing custom import file to disk ...'
  file_mkdir, file_dirname(filename)
  openw, lun, filename, /get_lun
  printf, lun, output
  free_lun, lun
  __aurorax_message, 'Finished, file saved to ' + filename
end

;+
; :Description:
;       Realize a browser window showing conjunction search results
;       in the AuroraX conjunction search website.
;
; :Parameters:
;       request_id: in, required, String
;         the request ID for the conjunction search
;
; :Keywords:
;       xsize: in, optional, Integer
;         specify the width of the browser window rendered, default is 95% of native screen width
;       ysize: in, optional, Integer
;         specify the height of the browser window rendered, default is 90% of native screen height
;       clipboard: in, optional, Boolean
;         copy the AuroraX URL to the clipboard
;       print_url: in, optional, Boolean
;         instead of rendering a browser window, print out the AuroraX URL
;       expert: in, optional, Boolean
;         open in the "expert mode" AuroraX conjunction search webpage
;
; :Examples:
;       response = aurorax_conjunction_search(start_ts, end_ts, distance, ground=ground, space=space)
;       aurorax_open_conjunctions_in_aurorax, response.request_id
;+
pro aurorax_open_conjunctions_in_aurorax, request_id, xsize = xsize, ysize = ysize, clipboard = clipboard_kw, print_url = url_kw, expert = expert_kw
  compile_opt idl2
  ; init
  max_conjunctions = 5000
  url = 'https://aurorax.space/conjunctionSearch/standard?requestID=' + request_id
  if keyword_set(expert_kw) then begin
    url = 'https://aurorax.space/conjunctionSearch/expert?requestID=' + request_id
  endif

  ; initialize values that aren't entered
  screen_size = get_screen_size()
  if (isa(xsize) eq 0) then xsize = screen_size[0] * 0.95
  if (isa(ysize) eq 0) then ysize = screen_size[1] * 0.9

  ; check that request is finished, and there aren't too many conjuncions
  status = __aurorax_request_get_status('conjunctions', request_id)
  if (isa(status.search_result.result_count) eq 0) then begin
    print, 'Error: this request has not completed yet, please wait and try again'
    return
  endif
  if (status.search_result.result_count ge max_conjunctions) then begin
    print, 'Error: too many conjunctions, reduce the parameters for your search to find less than ' + strtrim(max_conjunctions, 2) + ' conjunctions and try again'
    return
  endif

  ; check keywords
  if keyword_set(url_kw) then begin
    print, 'AuroraX URL: ' + url
  endif
  if keyword_set(clipboard_kw) then begin
    ; copy URL to clipboard
    Clipboard.set, url
    print, 'AuroraX URL copied to your clipboard!'
  endif
  if (keyword_set(url_kw) eq 0) and (keyword_set(clipboard_kw) eq 0) then begin
    ; realize the window
    window_parent = widget_base()
    browser = widget_browser(window_parent, value = url, xsize = xsize, ysize = ysize)
    widget_control, window_parent, /realize
  endif
end
