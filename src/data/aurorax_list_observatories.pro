;-------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;-------------------------------------------------------------

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_LIST_OVSERVATORIES
;
; PURPOSE:
;       Retrieve list of available observatories where an instrument exists.
;
; EXPLANATION:
;       Retrieve information about observatories, including full name, geodetic
;       latitude and longitude. Optional parameters are used to filter for certain
;       matching observatories.
;
; CALLING SEQUENCE:
;       aurorax_list_observatories(instrument_array)
;
; PARAMETERS:
;       insrument_array     the insrument array. Possible values are 'themis_asi',
;                           'rego', 'trex_rgb', 'trex_nir', and 'trex_blue'.
;       uid                 site unique identifier to filter on, optional
;
; OUTPUT
;       the found observatories
;
; OUTPUT TYPE:
;       a list of structs
;
; EXAMPLES:
;       observatories = aurorax_list_observatories('themis_asi')
;       observatories = aurorax_list_datasets('trex_rgb', uid='gill')
;+
;-------------------------------------------------------------
function aurorax_list_observatories,instrument_array,uid=uid
  ; set params
  param_str = '?instrument_array=' + instrument_array
  if (isa(uid) eq 1) then begin
    param_str += '&uid=' + uid
  endif

  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.phys.ucalgary.ca'
  req->SetProperty,URL_PATH = 'api/v1/data_distribution/observatories' + param_str
  req->SetProperty,HEADERS = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; serialize into struct
  status = json_parse(output,/TOSTRUCT)

  ; return
  return,status
end