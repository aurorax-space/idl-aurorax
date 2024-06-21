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

function aurorax_ucalgary_get_urls,dataset_name,start_ts,end_ts,site_uid=site_uid,device_uid=device_uid
  ; set required params
  param_str = '?name=' + dataset_name
  param_str += '&start=' + start_ts
  param_str += '&end=' + end_ts

  ; set optional params
  if (isa(site_uid) eq 1) then begin
    param_str += '&site_uid=' + site_uid
  endif
  if (isa(device_uid) eq 1) then begin
    param_str += '&device_uid=' + device_uid
  endif

  ; set up request
  req = OBJ_NEW('IDLnetUrl')
  req->SetProperty,URL_SCHEME = 'https'
  req->SetProperty,URL_PORT = 443
  req->SetProperty,URL_HOST = 'api.phys.ucalgary.ca'
  req->SetProperty,URL_PATH = 'api/v1/data_distribution/urls' + param_str
  req->SetProperty,HEADERS = 'User-Agent: idl-aurorax/' + __aurorax_version()

  ; make request
  output = req->Get(/STRING_ARRAY)

  ; serialize into struct
  status = json_parse(output,/TOSTRUCT)

  ; return
  return,status
end