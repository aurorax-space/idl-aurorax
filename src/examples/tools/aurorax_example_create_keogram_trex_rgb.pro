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

pro aurorax_example_create_keogram_trex_rgb

  ; First, download and read an hour of TREx RGB data
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', '2023-02-24T06:00:00', '2023-02-24T06:59:59', site_uid="rabb")
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Download and read the corresponding skymap
  ; Download all skymaps in 3 years leading up to date of interest
  d = aurorax_ucalgary_download('TREX_RGB_SKYMAP_IDLSAV', '2019-02-24T06:00:00', '2023-02-24T06:59:59', site_uid='rabb')

  ; Read in all of the skymaps that were found
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Grab the *last* skymap out of the skymap data struct as this is most recent to date of interest
  skymap = skymap_data.data[-1]

  ; Now extract the image array and timestamps from the image data structure
  img = image_data.data
  time_stamp = image_data.timestamp

  ; Create keogram object
  keo = aurorax_keogram_create(img, time_stamp)

  ; If you wanted to further manipulate or manually plot the keogram
  ; array, you can grab it like this:
  keo_arr = keo.data

  ; Add geographic and elevation axes to the keogram object
  keo = aurorax_keogram_add_axis(keo, skymap, /geo, /elev, altitude_km=110)

  ; Plot with aurorax function
  aurorax_keogram_plot, keo, title="Geographic", /geo, location=[0,0], dimensions=[1000,400]
  aurorax_keogram_plot, keo, title="Elevation", /elev, location=[0,420], dimensions=[1000,400]

end