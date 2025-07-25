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

pro aurorax_example_create_custom_keogram
  ; ------------------------==
  ; Creating a Custom Keograms
  ; ------------------------==
  ;
  ; We can generate keograms from a custom slice of a set of images. The slice used is defined
  ; by a set of points in CCD, geographic, or geomagnetic coordinates, within the bounds of
  ; the image data.
  ; 
  
  ; First, download and read an hour of TREx RGB data
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', '2021-11-04T03:00:00', '2021-11-04T03:59:59', site_uid = 'gill')
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Download best matching skymap for the given site and timestamp
  d = aurorax_ucalgary_download_best_skymap('TREX_RGB_SKYMAP_IDLSAV', 'gill', '2021-11-04T03:00:00')

  ; Read in all of the skymaps that were found
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Grab the *last* skymap out of the skymap data struct as this is most recent to date of interest
  skymap = skymap_data.data[0]

  ; Now extract the image array and timestamps from the image data structure
  img = image_data.data
  time_stamp = image_data.timestamp

  ; Obtain some lats/lons that define the keogram slice of interest
  latitudes = findgen(50, start = 51, increment = 0.22)
  longitudes = -102.0 + 5 * sin(!pi * (latitudes - 51.0) / (62.0 - 51.0))
  
  ; Create the custom keogram along the above defined lats/lons
  keo = aurorax_keogram_create_custom(img, time_stamp, 'geo', longitudes, latitudes, $
                                      /show_preview, skymap = skymap, altitude_km = 113)

  ; Display the keogram, using aspect ratio to manually stretch the height, as the resuling
  ; keogram will be quite short, as we sampled 50 data points, giving a height of only 49 pixels
  p = aurorax_keogram_plot(keo, title = 'Custom Keogram - Median (Default)', location = [0,0], $
                           dimensions = [1000,400], aspect_ratio = 12)
  
  ; Each 'bin' in a custom keogram may have any number of image pixels
  ; within it, depending on how the actual contour along which the keogram
  ; is defined. Thus, a 'metric' must be chosen to determine how the pixels
  ; will contribute to each keogram bin. The default, is to take the median
  ; value across all pixels within each bin, and use the result to fill that
  ; bin. Alternatively, the metric keyword can be set to 'sum', 'mean', or
  ; 'percentile', for other computation methods
  ; 
  ; Create another custom keogram along the same contour, but this time
  ; using the percentile method, and plot it
  keo = aurorax_keogram_create_custom(img, time_stamp, 'geo', longitudes, latitudes, $
                                      skymap = skymap, altitude_km = 113, $
                                      metric='percentile', percentile = 95.0)
  p = aurorax_keogram_plot(keo, title = 'Custom Keogram - 95th Percentile', location = [0,450], $
                           dimensions = [1000,400], aspect_ratio = 12)
end