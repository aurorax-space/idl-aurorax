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

pro aurorax_example_create_keogram_themis
  ; First, download and read an hour of THEMIS data
  d = aurorax_ucalgary_download('THEMIS_ASI_RAW', '2021-11-04T09:00:00', '2021-11-04T09:59:59', site_uid = 'fsim')
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Download and read the corresponding skymap
  d = aurorax_ucalgary_download_best_skymap('THEMIS_ASI_SKYMAP_IDLSAV', 'fsim', '2021-11-04T09:00:00')

  ; Read in all of the skymaps that were found
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  skymap = skymap_data.data[0]

  ; Now extract and scale the image array and timestamps from the image data structure
  img = bytscl(image_data.data, 2000, 15000)
  time_stamp = image_data.timestamp

  ; Create keogram object
  keo = aurorax_keogram_create(img, time_stamp)

  ; If you wanted to further manipulate or manually plot the keogram
  ; array, you can grab it like this:
  keo_arr = keo.data
  
  ; Add geographic, elevation, and geomagnetic axes to the keogram object
  keo = aurorax_keogram_add_axis(keo, skymap, /geo, /elev, /mag, altitude_km=112)
  
  ; Plot with aurorax function
  p1 = aurorax_keogram_plot(keo, title = 'Geographic', /geo, location = [0, 0], dimensions = [800, 400])
  p2 = aurorax_keogram_plot(keo, title = 'Elevation', /elev, location = [800, 0], dimensions = [800, 400])
  p3 = aurorax_keogram_plot(keo, title = 'Geomagnetic (AACGM)', /mag, location = [0, 450], dimensions = [800, 400], y_tick_interval = 25)
  
  ;  === Dealing with missing data ===
  ;
  ; When a keogram is created with aurorax_keogram_create() it will, by default, only include timetamps
  ; for which data exists. You may want to indicate missing data in the keogram, and this can be easily
  ; achieved using the aurorax_keogram_inject_nans() function.
  ;
  ; As an example, the below code creates a keogram for a different date with some missing data, and
  ; then calls the aurorax_keogram_inject_nans() function before plotting.

  ; Download and read some more THEMIS image data
  d = aurorax_ucalgary_download('THEMIS_ASI_RAW', '2017-10-29T10:00:00', '2017-10-29T10:59:00', site_uid = 'inuv')
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  img = bytscl(image_data.data, 1000, 6000)
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
