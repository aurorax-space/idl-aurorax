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
;       Retrieve list of available observatories where an instrument exist,
;       including full name, geodetic latitude and longitude. Optional parameters
;       are used to filter for certain matching observatories.
;
; :Parameters:
;       instrument_array: in, required, String
;         the instrument array. Possible values are 'themis_asi', 'rego', 'trex_rgb',
;         'trex_nir', 'trex_blue', 'trex_spectrograph', and 'smile_asi'.
;
; :Keywords:
;       uid: in, optional, String
;         site unique identifier to filter on
;
; :Returns:
;       List(Structure)
;
; :Examples:
;       observatories = aurorax_list_observatories('themis_asi')
;       observatories = aurorax_list_observatories('trex_rgb', uid='gill')
;+
function aurorax_list_observatories, instrument_array, uid = uid
  ; set params
  param_str = '?instrument_array=' + instrument_array
  if (isa(uid) eq 1) then begin
    param_str += '&uid=' + uid
  endif

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.phys.ucalgary.ca'
  req.setProperty, url_path = 'api/v1/data_distribution/observatories' + param_str
  req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  r = __aurorax_perform_api_request('get', 'aurorax_list_observatories', req)
  if (r.status_code ne 200) then return, !null
  output = r.output

  ; cleanup this request
  obj_destroy, req

  ; serialize into struct
  status = json_parse(output, /tostruct)

  ; return
  return, status
end
