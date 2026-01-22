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
;       Retrieve information about available datasets, including provider,
;       short+long descriptions, and DOI details. Optional parameters are
;       used to filter for certain matching datasets.
;
; :Keywords:
;       name: in, optional, String
;         The dataset name to filter on. This is used for partial matches too, and is
;         case insensitive.
;       level: in, optional, String
;         Supply a level string for filtering. Valid strings are: L0, L1, L1A, L2, L3. Value
;         is case insensitive.
;
; :Returns:
;       List(Structure)
;
; :Examples:
;       datasets = aurorax_list_datasets(name='themis_asi')
;       datasets = aurorax_list_datasets(name='trex')
;+
function aurorax_list_datasets, name = name, level = level
  ; set params
  param_str = '?'
  if keyword_set(name) then begin
    param_str += 'name=' + name.toLower()
  endif
  if keyword_set(level) then begin
    param_str += '&level=' + level.toLower()
  endif

  ; set up request
  req = obj_new('IDLnetUrl')
  req.setProperty, url_scheme = 'https'
  req.setProperty, url_port = 443
  req.setProperty, url_host = 'api.phys.ucalgary.ca'
  req.setProperty, url_path = 'api/v1/data_distribution/datasets' + param_str
  req.setProperty, headers = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  r = __aurorax_perform_api_request('get', 'aurorax_list_datasets', req)
  if (r.status_code ne 200) then return, !null
  output = r.output

  ; cleanup this request
  obj_destroy, req

  ; serialize into struct
  status = json_parse(output, /tostruct)

  ; filter out any that shouldn't show, based on the supported_libraries value
  filtered_sources = list()
  for i = 0, n_elements(status) - 1 do begin
    if (status[i].supported_libraries.where('idl-aurorax') ne !null) then begin
      filtered_sources.add, status[i]
    endif
  endfor

  ; return
  return, filtered_sources
end
