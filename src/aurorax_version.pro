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

function __aurorax_version
  compile_opt hidden
  return, '1.4.1'
end

;+
; :Description:
;       Check if there is a new version available.
;
;       This function will return an integer:
;         0 = update not available
;         1 = update available
;         2 = error encountered
;
; :Keywords:
;       quiet: in, optional, Boolean
;         Do not output any print statements
;
; :Returns:
;       Struct

; :Examples:
;       aurorax_check_version
;+
function aurorax_check_version, quiet = quiet
  ; init
  quiet_flag = 0
  if (keyword_set(quiet)) then quiet_flag = 1

  ; get current version
  curr_version = __aurorax_version()

  ; make request to Github to get latest release from the idl-aurorax repository
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.github.com'
  req.setProperty, url_path = 'repos/aurorax-space/idl-aurorax/releases/latest'
  req.setProperty, timeout = 5000

  ; check for error
  catch, error_status
  if (error_status ne 0) then begin
    catch, /cancel
    req.getProperty, response_code = status_code
    obj_destroy, req

    ; evaluate error code
    if (quiet_flag ne 1) then begin
      if (status_code eq 28) then begin
        print, '[aurorax_check_version] Timeout encountered when reaching out to Github. Perhaps check your internet connection, or connection to Github.'
      endif else begin
        print, '[aurorax_check_version] Unknown error encountered when reaching out to Github (error code ' + string(status_code, format = '(I0)') + ')'
      endelse
    endif

    ; bail out
    return, -1
  endif

  ; make request
  output = req.get(/string_array)

  ; serialize output, extract the version number
  status = json_parse(output)
  latest_version = status['name'].toLower()
  if (latest_version.startsWith('v') eq 1) then begin
    latest_version = latest_version.substring(1)
  endif

  ; check version
  new_version_available = 0
  curr_version_split = strsplit(curr_version, '.', /extract)
  latest_version_split = strsplit(latest_version, '.', /extract)
  if (fix(latest_version_split[0]) gt fix(curr_version_split[0])) then begin
    ; major version update available
    new_version_available = 1
  endif else if (fix(latest_version_split[1]) gt fix(curr_version_split[1])) then begin
    ; feature version update available
    new_version_available = 1
  endif else if (fix(latest_version_split[2]) gt fix(curr_version_split[2])) then begin
    ; bugfix version update available
    new_version_available = 1
  endif

  ; print
  message = ''
  if (new_version_available eq 0) then begin
    message = '[aurorax_check_version] No new version is available. Your version, ' + curr_version + ', is the ' + $
      'latest. More information can be found at https://github.com/aurorax-space/idl-aurorax/releases'
    if (quiet_flag ne 1) then begin
      print, message
    endif
  endif else begin
    message = '[aurorax_check_version] New version is available! Version ' + latest_version + ' can be installed (' + $
      'currently have ' + curr_version + '). Upgrade information can be found at ' + $
      'https://github.com/aurorax-space/idl-aurorax?tab=readme-ov-file#updating'
    if (quiet_flag ne 1) then begin
      print, message
    endif
  endelse

  ; construct return struct
  return_struct = {new_version_available: new_version_available, curr_version: curr_version, latest_version: latest_version, message: message}

  ; return
  return, return_struct
end
