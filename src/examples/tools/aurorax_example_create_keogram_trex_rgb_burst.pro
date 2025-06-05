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

pro aurorax_example_create_keogram_trex_rgb_burst
  ; ---------------------------------
  ; Creating a TREx RGB Burst Keogram
  ; ---------------------------------
  ;
  ; Keograms are a useful data product that can be generated from ASI image data. A keogram is created
  ; by stacking slices of the middle column (a N-S slice for the orientation of the UCalgary imagers)
  ; of pixels from ASI images over a period of time.
  ;
  ; Below, we'll work through the creation of a 5 minute keogram created from
  ; TREx-RGB 3 Hz Burst Mode data.
  ;
  
  ; Download 5 minute of TREx RGB Burst data. Burst data is extremely large.
  ; When working with burst data, it is best to load it in smaller chunks.
  ; The ability to read in burst data files will depend on your computer's
  ; resources, as large amounts of data will require more memory.
  ;
  ; For now, let's download 5 minutes of burst data. This is enough
  ; to make a keogram due to the high cadence.
  d = aurorax_ucalgary_download('TREX_RGB_RAW_BURST', '2023-02-24T06:00:00', '2023-02-24T06:04:59', site_uid = 'rabb')
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  
  ; From this point on, the process for creating a keogram is identical to non-burst data
  ; just weary of memory constraints imposed by this large data
  
  ; Now extract the image array and timestamps from the image data structure
  img = image_data.data
  time_stamp = image_data.timestamp

  ; Create keogram object
  keo = aurorax_keogram_create(img, time_stamp)

  ; If you wanted to further manipulate or manually plot the keogram
  ; array, you can grab it like this:
  keo_arr = keo.data

  ;------------------------------------
  ; Reference in geographic coordinates
  ;
  ; For each camera, the UCalgary maintains a geospatial calibration dataset that maps pixel
  ; coordinates (detector X and Y) to local observer and geodetic coordinates (at altitudes
  ; of interest). We refer to this calibration as a 'skymap'. The skymaps may change due to
  ; the freeze-thaw cycle and changes in the building, or when the instrument is serviced.
  ; A skymap is valid for a range of dates. The metadata contained in a file includes the
  ; start and end dates of the period of its validity.
  ;
  ; Be sure you choose the correct skymap for your data timeframe. The aurorax_download_best_skymap()
  ; function is there to help you, but for maximum flexibility you can download a range of skymap
  ; files and use whichever you prefer. For a complete breakdown of how to choose the correct
  ; skymap for the data you are working with, refer to the crib sheet:
  ;
  ;     aurorax_example_skymaps.pro
  ;
  ; All skymaps can be viewed by looking at the data tree for
  ; the imager you are using (see https://data.phys.ucalgary.ca/). If you believe the geospatial
  ; calibration may be incorrect, please contact the UCalgary team.
  ;
  ; For more on the skymap files, please see the skymap file description document:
  ;   https://data.phys.ucalgary.ca/sort_by_project/other/documentation/skymap_file_description.pdf
  ;
  
  ; Download and read the corresponding skymap
  d = aurorax_ucalgary_download_best_skymap('TREX_RGB_SKYMAP_IDLSAV', 'rabb', '2023-02-24T06:00:00')
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  skymap = skymap_data.data[0]
  
  ; Add geographic and elevation axes to the keogram object
  keo = aurorax_keogram_add_axis(keo, skymap, /geo, /elev, altitude_km = 110)

  ; Plot with aurorax function
  p1 = aurorax_keogram_plot(keo, title = 'TREx RGB Burst Data (Geographic Axis)', /geo, location = [0, 0], dimensions = [1000, 400])
  p2 = aurorax_keogram_plot(keo, title = 'TREx RGB Burst Data (Elevation Axis)', /elev, location = [0, 420], dimensions = [1000, 400])
end