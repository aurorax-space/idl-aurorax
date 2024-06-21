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

pro aurorax_example_read_data
  ; download an hour of THEMIS ASI data
  d = aurorax_ucalgary_download('THEMIS_ASI_RAW','2022-01-01T06:00:00','2022-01-01T06:59:59',site_uid='gill')

  ; set list of files to read
  f = d.filenames

  ; read the data
  data = aurorax_ucalgary_read(d.dataset,f)
  help,data

  ; read the data quietly
  data = aurorax_ucalgary_read(d.dataset,f[0],/quiet)

end