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
;       AURORAX_UCALGARY_GET_URLS
;
; PURPOSE:
;       Retrieve list of URLS that can be downloaded from the UCalgary
;       Open Data Platform.
;
; EXPLANATION:
;       Retrieve the URLs of files available for download from the UCalgary
;       Open Data Platform, for the given dataset, timeframe, and optional
;       site/device. This function is used by the aurorax_ucalgary_download()
;       function.
;
; CALLING SEQUENCE:
;       aurorax_ucalgary_get_urls(dataset_name, start_ts, end_ts)
;
; PARAMETERS:
;       dataset_name       name of the dataset to get URLs of data files for
;       start_ts           start timestamp, format as ISO time string (YYYY-MM-DDTHH:MM:SS)
;       end_ts             end timestamp, format as ISO time string (YYYY-MM-DDTHH:MM:SS)
;       site_uid           unique 4-letter site UID to filter on (e.g., atha, gill, fsmi), optional
;       device_uid         unique device UID to filter on (e.g., themis08, rgb-09), optional
;
; OUTPUT
;       information about the available URLs of data files
;
; OUTPUT TYPE:
;       a struct
;
; EXAMPLES:
;       u = aurorax_ucalgary_get_urls('THEMIS_ASI_RAW','2022-01-01T06:00:00','2022-01-01T06:59:59',site_uid='atha')
;       u = aurorax_ucalgary_get_urls('TREX_RGB_RAW_NOMINAL','2022-01-01T06:00:00','2022-01-01T06:00:00')
;+
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