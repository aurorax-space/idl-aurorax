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

pro aurorax_example_montage_trex_rgb
  ; First, download and read some TREx RGB data
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', '2023-02-24T06:00:00', '2023-02-24T06:09:59', site_uid = 'rabb')
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Extract the image data array and timestamp array
  img = image_data.data
  ts = image_data.timestamp

  ; Create a montage, using 20 as a frame steo, effectively making the montage at a 1-minute cadence
  aurorax_montage_create, img, ts, 5, 2, frame_step = 20
end
