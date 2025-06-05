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

pro aurorax_example_extract_luminosity_from_bounding_box_trex_rgb
  ; ------------------------------------------------
  ; Working with Bounding Boxes - Multi Channel Data
  ; ------------------------------------------------
  ;
  ; When using ASI data, it is often advantageous to restrict your area of study to a
  ; particular region of the ASI. Perhaps you'd like to isolate one region of some patchy
  ; pulsating aurora or isolate an arc, or maybe you're only interested in a specific
  ; region of geomagnetic latitudes and longitudes.
  ;
  ; The aurorax_bounding_box_extract_metric() functions provides various options for using
  ; bounding boxes to analyze regions of ASI data for a series of images. We'll explore
  ; some different things you can do below, using multi-channel (RGB) ASI data, usng TREx
  ; RGB as an example.
  ;
  
  ; Download an hour of TREx RGB data
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', '2021-11-04T03:00:00', '2021-11-04T03:59:59', site_uid = 'gill')

  ; Read the image data
  image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  
  ; Download best matching skymap for the given site and timestamp
  d = aurorax_ucalgary_download_best_skymap('TREX_RGB_SKYMAP_IDLSAV', 'gill', '2021-11-04T03:00:00')

  ; Read in all of the skymaps that were found
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)

  ; Get images and timestamp arrays from the image data object
  images = image_data.data
  timestamps = image_data.timestamp

  ; Grab the *last* skymap out of the skymap data struct as this is most recent to date of interest
  skymap = skymap_data.data[-1]

  ; Extract some data within bounds of azimuth, CCD, elevation, and geo lats
  azim_bounds = [134, 143]
  luminosity_in_azim = aurorax_bounding_box_extract_metric(images, 'azim', azim_bounds, skymap = skymap, /show_preview)

  ; For this one, lets get the mean, using the metric keyword. By default, the median
  ; is returned, but one can also obtain the mean or sum of data within the desired bounds
  ccd_bounds = [140, 173, 140, 160]
  luminosity_in_ccd = aurorax_bounding_box_extract_metric(images, 'ccd', ccd_bounds, metric = 'mean', skymap = skymap, /show_preview)

  elev_bounds = [40, 60]
  luminosity_in_elev = aurorax_bounding_box_extract_metric(images, 'elev', elev_bounds, skymap = skymap, /show_preview)
  
  ; Using the percentile keyword indicates the use of a different metric, i.e.
  ; taking the value (e.g. 90th) percentile within the bounding box
  geo_bounds = [-94, -95, 55, 55.5]
  luminosity_in_geo = aurorax_bounding_box_extract_metric(images, 'geo', geo_bounds, percentile = 90, skymap = skymap, altitude_km = 112, /show_preview)
  
  ; Geomagnetic (AACGM) coordinates may also be used to define a bounding box
  ; This is done by setting the mode parameter to 'mag'
  mag_bounds = [-25, -20, 65.0, 65.5]
  luminosity_in_mag = aurorax_bounding_box_extract_metric(images, 'mag', mag_bounds, skymap = skymap, altitude_km = 112, /show_preview)
  
  ; Let's plot the data exctracted from the RGB images withing the geo bounds
  ; For multi channel image data, the metric will be returned for each channel
  p = plot(reform(luminosity_in_geo[0, *]), color = 'red', location=[800,0], title='90th Percentile R-G-B Data Numbers within Lat/Lon')
  p = plot(reform(luminosity_in_geo[1, *]), color = 'green', /overplot)
  p = plot(reform(luminosity_in_geo[2, *]), color = 'blue', /overplot)
  
  ; Make the same plot for the data extracted from the geomagnetic bounding box
  p = plot(reform(luminosity_in_mag[0, *]), color = 'red', location=[800,500], title='Median R-G-B Data Number within Magnetic Lat/Lon')
  p = plot(reform(luminosity_in_mag[1, *]), color = 'green', /overplot)
  p = plot(reform(luminosity_in_mag[2, *]), color = 'blue', /overplot)
end