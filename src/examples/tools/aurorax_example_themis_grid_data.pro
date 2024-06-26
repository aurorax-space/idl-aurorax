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

pro aurorax_example_themis_grid_data

  ; First, download and read an hour of TREx RGB data
  d = aurorax_ucalgary_download('THEMIS_ASI_GRID_MOSV001', '2023-02-24T06:00:00', '2023-02-24T06:59:59')
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)

end