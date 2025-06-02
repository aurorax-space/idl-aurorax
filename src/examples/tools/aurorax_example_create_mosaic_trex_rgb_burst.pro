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

pro aurorax_example_create_mosaic_trex_rgb_burst
  ; Initialize list to hold image data and skymaps
  image_list = list()
  skymap_list = list()

  ; Date of Interest
  date_time = '2023-02-24T06:15:00'

  ; Iterate through sites we want to included in the mosaic
  foreach site, ['gill', 'rabb'] do begin
    ; download and read image data for this site and add to list
    d = aurorax_ucalgary_download('TREX_RGB_RAW_BURST', date_time, date_time, site_uid = site)
    image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    
    ; OPTIONALLY MANUALLY SPLIT BURST DATA INTO SMALLER CHUNKS
    ; A single minute of burst data will be quite large (~3 Hz * 60 s = ~180 Frames)
    ; If you are struggling/concerned with memory constraints, it is advised
    ; to split up and only work with smaller chunks of burst data. This may or may
    ; not be necessary depending on your available computational resources.

    ; For the sake of this tutorial, let's slice out the first 25 frames. For consistency
    ; we slice the image data, the metadata, and the timestamps identically. In this case
    ; we will be preparing 25 frames / ~3 Hz = ~8.33 s of data. Beginning at the first frame
    ; for our given timestamp, this means we will prepare mosaic data for ~ 06:15:00.00-06:15:08.33 UTC

    ; Regardless, if you are only interested in a specific timeframe,
    ; doing this will speed up data-processing
    image_data.data = image_data.data[0:25]
    image_data.timestamp = image_data.timestamp[0:25]
    image_data.metadata = image_data.metadata[0:25]
    
    image_list.add, image_data

    ; download and read the correct skymap for this site and add to list
    d = aurorax_ucalgary_download_best_skymap('TREX_RGB_SKYMAP_IDLSAV', site, date_time)
    skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    skymap = skymap_data.data[0]
    skymap_list.add, skymap
  endforeach

  ; Prepare image data and skymaps for mosaic plotting
  altitude_km = 110
  prepped_images = aurorax_mosaic_prep_images(image_list)
  prepped_skymaps = aurorax_mosaic_prep_skymap(skymap_list, altitude_km)
  
  ; Now, we need to create a direct graphics map that the data can be plotted
  ; onto. Using, the map_set procedure (see IDL docs for info), create the map
  ; however you'd like. Below is an example
  land_color = aurorax_get_decomposed_color([186, 186, 186])
  water_color = aurorax_get_decomposed_color([64, 89, 120])
  border_color = aurorax_get_decomposed_color([0, 0, 0])
  border_thick = 2
  window_bg_color = aurorax_get_decomposed_color([0, 0, 0])

  ; set up map projection
  map_bounds = [40, 220, 80, 290]
  ilon = 255
  ilat = 56

  ; plot the empty map in a window
  window, 0, xsize = 800, ysize = 600, xpos = 0
  map_win_loc = [0., 0., 1., 1.]
  device, decomposed = 1
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, ilat, ilon, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, thick = border_thick

  ; Define scaling bounds for image data - in this case we just use an array to scale all sites
  ; the same - alternatively, one can use a hash to scale images on a per-site basis
  scale = [10, 105]

  ; Pick which time within the prepared data that you'd like to plot
  ;
  ; Note that the mosaic plotting function in AuroraX will search for the timestamp in the prepared
  ; data that is *closest* and within one-minute to the requested timestamp.
  mosaic_dt = '2023-02-24T06:15:00.78'

  ; Plot some gridlines
  gridline_color = aurorax_get_decomposed_color([0, 0, 0])
  clats = [30, 40, 50, 60, 70, 80]
  clons = [200, 220, 240, 260, 280, 300, 320, 340]
  aurorax_mosaic_oplot, constant_lats = clats, constant_lons = clons, color = gridline_color, linestyle = 2, thick = 2

  ; Call the mosaic creation function to plot the mosaic in the current window
  aurorax_mosaic_plot, prepped_images, prepped_skymaps, mosaic_dt, intensity_scales = scale

  ; Plot some text on top
  xyouts, 0.01, 0.9, 'TREx RGB - Burst Mode', /normal, font = 1, charsize = 6
  xyouts, 0.01, 0.085, strmid(mosaic_dt, 0, 10), /normal, font = 1, charsize = 5
  xyouts, 0.01, 0.01, strmid(mosaic_dt, 11, 11) + ' UTC', /normal, font = 1, charsize = 5
end
















