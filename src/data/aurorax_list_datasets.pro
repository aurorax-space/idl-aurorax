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
;       AURORAX_LIST_DATASETS
;
; PURPOSE:
;       Retrieve list of available datasets for which you can
;       download data.
;
; EXPLANATION:
;       Retrieve information about available datasets, including provider,
;       short+long descriptions, and DOI details. Optional parameters are
;       used to filter for certain matching datasets.
;
; CALLING SEQUENCE:
;       aurorax_list_datasets()
;
; PARAMETERS:
;       name         dataset name for filter on, case-sensitive and partial
;                    matches are allowed. Optional.
;
; OUTPUT
;       the found datasets
;
; OUTPUT TYPE:
;       a list of structs
;
; EXAMPLES:
;       datasets = aurorax_list_datasets()
;       datasets = aurorax_list_datasets(name='THEMIS_ASI')
;+
;-------------------------------------------------------------
function aurorax_list_datasets,name=name
  ; set params
  param_str = ''
  if (isa(name) eq 1) then begin
    param_str += '?name=' + name
  endif

  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.phys.ucalgary.ca'
  req->SetProperty,URL_PATH = 'api/v1/data_distribution/datasets' + param_str
  req->SetProperty,HEADERS = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; serialize into struct
  status = json_parse(output,/TOSTRUCT)

  ; return
  return,status
end