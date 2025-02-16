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

pro aurorax_example_create_mosaic_rego_rayleighs
  compile_opt idl2

  ; Create lists to hold all image data and skymap structures
  images_list = list()
  skymap_list = list()

  ; Date of Interest
  date_time = '2018-01-14T04:48:00'

  ; Set earliest date to search for calibration files
  start_search_ts = '2010-11-04T03:00:00'

  ; site_uids corresponding to each site we are adding data for
  device_uids = ['652', '656', '654']

  ; Iterate through sites we want to included in the mosaic
  foreach site, ['gill', 'fsmi', 'fsim'], i do begin
    ; download and read data for this site
    d = aurorax_ucalgary_download('REGO_RAW', date_time, date_time, site_uid = site)
    images = aurorax_ucalgary_read(d.dataset, d.filenames)
    raw_image_data = images.data
    ; * Calibrate the data before adding it to the data list
    device_uid = device_uids[i]

    ; Search through flatfield files and get the most recent one
    dataset_name = 'REGO_CALIBRATION_FLATFIELD_IDLSAV'
    d = aurorax_ucalgary_download(dataset_name, start_search_ts, date_time, device_uid = device_uid)
    flatfield_cal = (aurorax_ucalgary_read(d.dataset, d.filenames))[-1].data[0]

    ; Search through rayleighs files get the most recent one
    dataset_name = 'REGO_CALIBRATION_RAYLEIGHS_IDLSAV'
    d = aurorax_ucalgary_download(dataset_name, start_search_ts, date_time, device_uid = device_uid)
    rayleighs_cal = (aurorax_ucalgary_read(d.dataset, d.filenames))[-1].data[0]

    ; calibrate the images
    calibrated_images = aurorax_calibrate_rego(raw_image_data, cal_flatfield = flatfield_cal, cal_rayleighs = rayleighs_cal)

    ; replace data field in images with calibrated data, then add to list
    images.data = calibrated_images
    images_list.add, images

    ; download all skymaps in range, read them in, then append *most recent* to respective list
    d = aurorax_ucalgary_download_best_skymap('REGO_SKYMAP_IDLSAV', site, date_time)
    skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    skymap = skymap_data.data[0]
    skymap_list.add, skymap
  endforeach

  ; set altitude in km
  altitude = 230

  ; Prep the images and skymaps for plotting
  prepped_data = aurorax_mosaic_prep_images(images_list)
  prepped_skymap = aurorax_mosaic_prep_skymap(skymap_list, altitude)

  ; Now, we need to create a direct graphics map that the data can be plotted
  ; onto. Using, the map_set procedure (see IDL docs for info), create the map
  ; however you'd like. Below is an example
  land_color = aurorax_get_decomposed_color([186, 186, 186])
  water_color = aurorax_get_decomposed_color([64, 89, 120])
  border_color = aurorax_get_decomposed_color([0, 0, 0])
  border_thick = 2
  window_bg_color = aurorax_get_decomposed_color([0, 0, 0])

  map_bounds = [40, 220, 80, 290]
  ilon = 255
  ilat = 56

  window, 0, xsize = 800, ysize = 600, xpos = 0
  map_win_loc = [0., 0., 1., 1.]
  device, decomposed = 1
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, ilat, ilon, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, thick = border_thick

  ; Scale all data the same, since we're working with absolute intensity
  scale = [0, 5000]

  ; Plot the first frame
  image_idx = 0

  ; Mask elevation below 10 degrees
  min_elevation = 10

  ; Use red colormap for REGO
  ct = 3

  ; Plot some gridlines
  gridline_color = aurorax_get_decomposed_color([0, 0, 0])
  clats = [30, 40, 50, 60, 70, 80]
  clons = [200, 220, 240, 260, 280, 300, 320, 340]
  aurorax_mosaic_oplot, constant_lats = clats, constant_lons = clons, color = gridline_color, linestyle = 2, thick = 2

  ; Call the mosaic creation function to plot the mosaic in the current window
  aurorax_mosaic_plot, prepped_data, prepped_skymap, image_idx, intensity_scales = scale, colortable = ct, min_elevation = min_elevation

  ; Plot some text on top
  xyouts, 0.01, 0.9, 'REGO - Absolute Intensity', /normal, font = 1, charsize = 6
  xyouts, 0.01, 0.085, strmid(images.timestamp[0], 0, 10), /normal, font = 1, charsize = 5
  xyouts, 0.01, 0.01, strmid(images.timestamp[0], 11, 8) + ' UTC', /normal, font = 1, charsize = 5
end
