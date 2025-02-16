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

; -------------------------------------------------------------
;+
; NAME:
;       AURORAX_GET_DATASET
;
; PURPOSE:
;       Retrieve specific dataset for which you can download data.
;
; EXPLANATION:
;       Retrieve information about a specific dataset, including provider,
;       short+long descriptions, and DOI details.
;
; CALLING SEQUENCE:
;       aurorax_get_dataset()
;
; PARAMETERS:
;       name         dataset name to retrieve, case-insensitive
;
; OUTPUT
;       the found dataset
;
; OUTPUT TYPE:
;       a struct
;
; EXAMPLES:
;       dataset = aurorax_get_dataset("THEMIS_ASI_RAW")
;+
;-------------------------------------------------------------
function aurorax_get_dataset, name
  compile_opt idl2
  ; set params
  param_str = '?name=' + name

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.phys.ucalgary.ca'
  req.setProperty, url_path = 'api/v1/data_distribution/datasets' + param_str
  req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req.get(/string_array)

  ; serialize into struct
  status = json_parse(output, /tostruct)

  ; remove all but the matching dataset
  matched_dataset = !null
  for i = 0, n_elements(status) - 1 do begin
    if (status[i].name eq name) then begin
      matched_dataset = status[i]
    endif
  endfor

  ; return
  return, matched_dataset
end
