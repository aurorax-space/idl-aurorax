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

pro spectrograph_example
  ; download an hour of TREx Spectrograph data
  ;
  ; using the aurorax_list_datasets() function, we figured out that
  ; the dataset names we want to use
  d = aurorax_ucalgary_download('TREX_SPECT_RAW', '2019-01-01T06:00:00', '2019-01-01T06:59:59', site_uid = 'luck')
  f = d.filenames
  data = aurorax_ucalgary_read(d.dataset, f)
  help, data
  data = aurorax_ucalgary_read(d.dataset, f[0], /quiet)
  help, data

  d = aurorax_ucalgary_download('TREX_SPECT_PROCESSED_V1', '2019-01-01T06:00:00', '2019-01-01T06:59:59', site_uid = 'luck')
  f = d.filenames
  data = aurorax_ucalgary_read(d.dataset, f)
  help, data
end
