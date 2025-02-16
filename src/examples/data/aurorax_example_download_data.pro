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

pro aurorax_example_download_data
  compile_opt idl2
  ; download an hour of THEMIS ASI data
  ;
  ; using the aurorax_list_datasets() function, we figured out that
  ; the dataset names we want to use
  d = aurorax_ucalgary_download('THEMIS_ASI_RAW', '2022-01-01T06:00:00', '2022-01-01T06:59:59', site_uid = 'atha')
  help, d
  print, ''

  ; download with no output
  d = aurorax_ucalgary_download('THEMIS_ASI_RAW', '2022-01-01T06:00:00', '2022-01-01T06:59:59', site_uid = 'atha', /quiet)
  print, ''

  ; download one minute of data from all sites
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', '2022-01-01T06:00:00', '2022-01-01T06:00:00')
  print, ''

  ; download force redownload of data, even if it exists locally already
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', '2022-01-01T06:00:00', '2022-01-01T06:00:00', /overwrite)
  print, ''
end
