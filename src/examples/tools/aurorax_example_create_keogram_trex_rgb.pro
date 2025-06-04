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

pro aurorax_example_create_keogram_trex_rgb
  ; First, download and read an hour of TREx RGB data
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', '2023-02-24T06:00:00', '2023-02-24T06:59:59', site_uid = 'rabb')
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Download and read the corresponding skymap
  d = aurorax_ucalgary_download_best_skymap('TREX_RGB_SKYMAP_IDLSAV', 'rabb', '2023-02-24T06:00:00')

  ; Read in all of the skymaps that were found
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  skymap = skymap_data.data[0]

  ; Now extract the image array and timestamps from the image data structure
  img = image_data.data
  time_stamp = image_data.timestamp

  ; Create keogram object
  keo = aurorax_keogram_create(img, time_stamp)

  ; If you wanted to further manipulate or manually plot the keogram
  ; array, you can grab it like this:
  keo_arr = keo.data

  ; Add geographic, elevation, and geomagnetic axes to the keogram object
  keo = aurorax_keogram_add_axis(keo, skymap, /geo, /elev, /mag, altitude_km = 110)

  ; Plot with aurorax function
  p1 = aurorax_keogram_plot(keo, title = 'Geographic', /geo, location = [0, 0], dimensions = [800, 400])
  p2 = aurorax_keogram_plot(keo, title = 'Elevation', /elev, location = [800, 0], dimensions = [800, 400])
  p3 = aurorax_keogram_plot(keo, title = 'Geomagnetic (AACGM)', /mag, location = [0, 450], dimensions = [800, 400])


  ;  === Dealing with missing data ===
  ;
  ; When a keogram is created with aurorax_keogram_create() it will, by default, only include timetamps
  ; for which data exists. You may want to indicate missing data in the keogram, and this can be easily
  ; achieved using the aurorax_keogram_inject_nans() function.
  ;
  ; As an example, the below code creates a keogram for a different date with some missing data, and
  ; then calls the aurorax_keogram_inject_nans() function before plotting.

  ; Download and read some more TREx RGB image data
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', '2022-03-12T10:00:00', '2022-03-12T10:59:59', site_uid = 'gill')
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  img = image_data.data
  time_stamp = image_data.timestamp

  ; Create keogram object
  keo = aurorax_keogram_create(img, time_stamp)
  original_shape = size(keo.data, /dimensions)
  
  ; Now call the aurorax_keogram_inject_nans()
  ;
  ; Note that by default, this function will determine the cadence of the image
  ; data automatically to determine where the missing data is, but a cadence keyword
  ; is also available to manually supply a cadence
  keo = aurorax_keogram_inject_nans(keo)
  new_shape = size(keo.data, /dimensions)
  
  ; Plot the keogram with missing data indicated as you normally would
  p4 = aurorax_keogram_plot(keo, title = 'Keogram with Missing Data', location = [800, 450], dimensions = [800, 400], colortable = 0)
  
  ; Inspecting the shape reveals that indeed there was missing data, which
  ; has been filled using the aurorax_keogram_inject_nans() function
  print
  print, "Original Keogram Shape:"
  print, original_shape
  print
  print, "Keogram Shape after aurorax_keogram_inject_nans():"
  print, new_shape
end