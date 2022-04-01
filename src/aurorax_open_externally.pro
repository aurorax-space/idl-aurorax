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
;       AURORAX_OPEN_CONJUNCTIONS_IN_SWARMAURORA
;
; PURPOSE:
;       Show conjunction search results in Swarm-Aurora
;
; EXPLANATION:
;       Realize a browser window showing conjunction search results
;       in Swarm-Aurora
;
; CALLING SEQUENCE:
;       aurorax_open_conjunctions_in_swarmaurora,request_id
;
; PARAMETERS:
;       request_id       the request ID for the conjunction search
;       xsize            specify the width of the browser window rendered, optional,
;                        default is 95% of native screen width
;       ysize            specify the height of the browser window rendered, optional,
;                        default is 90% of native screen height
;
; KEYWORDS:
;       /CLIPBOARD       copy the Swarm-Aurora URL to the clipboard
;       /PRINT_URL       instead of rendering a browser window, print out the Swarm-Aurora URL
;
; EXAMPLES:
;       ...
;       ...
;       response = aurorax_conjunction_search(start_dt,end_dt,distance,ground=ground,space=space)
;       aurorax_open_conjunctions_in_swarmaurora,response.request_id
;+
;-------------------------------------------------------------
pro aurorax_open_conjunctions_in_swarmaurora,request_id,xsize=xsize,ysize=ysize,CLIPBOARD=clipboard_kw,PRINT_URL=url_kw
  ; init
  max_conjunctions = 5000
  url = 'https://swarm-aurora.com/conjunctionFinder/?aurorax_request_id=' + request_id

  ; initialize values that aren't entered
  screen_size = get_screen_size()
  if (isa(xsize) eq 0) then xsize = screen_size[0] * 0.95
  if (isa(ysize) eq 0) then ysize = screen_size[1] * 0.9
  if (isa(xoffset) eq 0) then xoffset = 0
  if (isa(yoffset) eq 0) then yoffset = 0

  ; check that request is finished, and there aren't too many conjuncions
  status = __aurorax_request_get_status('conjunctions', request_id)
  if (isa(status.search_result.result_count) eq 0) then begin
    print,'Error: this request has not completed yet, please wait and try again'
    return
  endif
  if (status.search_result.result_count ge max_conjunctions) then begin
    print,'Error: too many conjunctions, reduce the parameters for your search to find less than ' + strtrim(max_conjunctions,2) + ' conjunctions and try again'
    return
  endif

  ; check keywords
  if keyword_set(url_kw) then begin
    print,'Swarm-Aurora URL: ' + url
  endif
  if keyword_set(clipboard_kw) then begin
    ; copy URL to clipboard
    Clipboard.Set,url
    print,'Swarm-Aurora URL copied to your clipboard!'
  endif
  if (keyword_set(url_kw) eq 0) and (keyword_set(clipboard_kw) eq 0) then begin
    ; realize the window
    window_parent = widget_base()
    browser = widget_browser(window_parent,value=url,xsize=xsize,ysize=ysize)
    widget_control,window_parent,/realize
  endif
end

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_SAVE_SWARMAURORA_CUSTOM_IMPORT_FILE
;
; PURPOSE:
;       Download a Swarm-Aurora custom import file
;
; EXPLANATION:
;       Retrieve a Swarm-Aurora custom import file for a conjunction
;       search request, and save it to a JSON file
;
; CALLING SEQUENCE:
;       aurorax_get_swarmaurora_custom_import_file,request_id
;
; PARAMETERS:
;       request_id       the request ID for the conjunction search
;       filename         the filename to save the custom import file to, optional,
;                        default is a filename made up from the current working directory
;                        of the IDL instance
;
; EXAMPLES:
;       ...
;       ...
;       response = aurorax_conjunction_search(start_dt,end_dt,distance,ground=ground,space=space)
;       aurorax_save_swarmaurora_custom_import_file,response.request_id
;+
;-------------------------------------------------------------
pro aurorax_save_swarmaurora_custom_import_file,request_id,filename=filename
  ; set filename
  cd,current=cwd
  if (isa(filename) eq 0) then filename = cwd + '\swarmaurora_custom_import_' + request_id + '.json'

  ; retrieve custom import file contents
  __aurorax_message,'Retrieving custom import file contents from Swarm-Aurora ...'
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'swarm-aurora.com'
  req->SetProperty,URL_PATH = 'conjunctionFinder/generate_custom_import_json'
  req->SetProperty,URL_QUERY = 'aurorax_request_id=' + request_id

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; cleanup
  obj_destroy,req

  ; write to file
  __aurorax_message,'Writing custom import file to disk ...'
  file_mkdir,file_dirname(filename)
  openw,lun,filename,/get_lun
  printf,lun,output
  free_lun,lun
  __aurorax_message,'Finished, file saved to ' + filename
end

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_OPEN_CONJUNCTIONS_IN_AURORAX
;
; PURPOSE:
;       Show conjunction search results in AuroraX website
;
;
; EXPLANATION:
;       Realize a browser window showing conjunction search results
;       in the AuroraX conjunction search website
;
; CALLING SEQUENCE:
;       aurorax_open_conjunctions_in_aurorax,request_id
;
; PARAMETERS:
;       request_id       the request ID for the conjunction search
;       xsize            specify the width of the browser window rendered, optional,
;                        default is 95% of native screen width
;       ysize            specify the height of the browser window rendered, optional,
;                        default is 90% of native screen height
;
; KEYWORDS:
;       /CLIPBOARD       copy the AuroraX URL to the clipboard
;       /PRINT_URL       instead of rendering a browser window, print out the AuroraX URL
;       /EXPERT          open in the "expert mode" AuroraX conjunction search webpage
;
; EXAMPLES:
;       ...
;       ...
;       response = aurorax_conjunction_search(start_dt,end_dt,distance,ground=ground,space=space)
;       aurorax_open_conjunctions_in_aurorax,response.request_id
;+
;-------------------------------------------------------------
pro aurorax_open_conjunctions_in_aurorax,request_id,xsize=xsize,ysize=ysize,CLIPBOARD=clipboard_kw,PRINT_URL=url_kw,EXPERT=expert_kw
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
  if (isa(xoffset) eq 0) then xoffset = 0
  if (isa(yoffset) eq 0) then yoffset = 0

  ; check that request is finished, and there aren't too many conjuncions
  status = __aurorax_request_get_status('conjunctions', request_id)
  if (isa(status.search_result.result_count) eq 0) then begin
    print,'Error: this request has not completed yet, please wait and try again'
    return
  endif
  if (status.search_result.result_count ge max_conjunctions) then begin
    print,'Error: too many conjunctions, reduce the parameters for your search to find less than ' + strtrim(max_conjunctions,2) + ' conjunctions and try again'
    return
  endif

  ; check keywords
  if keyword_set(url_kw) then begin
    print,'AuroraX URL: ' + url
  endif
  if keyword_set(clipboard_kw) then begin
    ; copy URL to clipboard
    Clipboard.Set,url
    print,'AuroraX URL copied to your clipboard!'
  endif
  if (keyword_set(url_kw) eq 0) and (keyword_set(clipboard_kw) eq 0) then begin
    ; realize the window
    window_parent = widget_base()
    browser = widget_browser(window_parent,value=url,xsize=xsize,ysize=ysize)
    widget_control,window_parent,/realize
  endif
end
