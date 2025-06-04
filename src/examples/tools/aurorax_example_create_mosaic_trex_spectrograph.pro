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

pro aurorax_example_create_mosaic_trex_spectrograph
  ; Minute of interest for downloading data
  date_time = '2021-03-13T09:40:00'
    
  ; Initialize list to hold image data and skymaps
  image_list = list()
  skymap_list = list()
  
  ; First, let's grab some TREx RGB data and skymaps to include in the mosaic
  foreach site, ['luck', 'gill', 'rabb'] do begin
    ; download and read image data for this site and add to list
    d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', date_time, date_time, site_uid = site)
    image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    image_list.add, image_data

    ; download and read the correct skymap for this site and add to list
    d = aurorax_ucalgary_download_best_skymap('TREX_RGB_SKYMAP_IDLSAV', site, date_time)
    skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    skymap = skymap_data.data[0]
    skymap_list.add, skymap
  endforeach
  
  ; Initialize list to hold image data and skymaps
  spect_list = list()
  spect_skymap_list = list()
  
  ; Now, let's also grab the spectrograph data and skymaps
  foreach site, ['luck', 'rabb'] do begin
    ; download and read spectrograph data for this site and add to list
    d = aurorax_ucalgary_download('TREX_SPECT_PROCESSED_V1', date_time, date_time, site_uid = site)
    spect_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    spect_list.add, spect_data

    ; download and read the correct skymap for this site and add to list
    d = aurorax_ucalgary_download_best_skymap('TREX_SPECT_SKYMAP_IDLSAV', site, date_time)
    skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    skymap = skymap_data.data[0]
    spect_skymap_list.add, skymap
  endforeach
  
  ; Prep the ASI and spectrograph data/skymaps seperately
  altitude_km = 115.0
  prepped_asi_images = aurorax_mosaic_prep_images(image_list)
  prepped_asi_skymaps = aurorax_mosaic_prep_skymap(skymap_list, altitude_km)
  prepped_spect_images = aurorax_mosaic_prep_images(spect_list)
  prepped_spect_skymaps = aurorax_mosaic_prep_skymap(spect_skymap_list, altitude_km)
  
  ; Combine the prepared ASI and spectrograph data/skymaps. Make sure the ASI data 
  ; comes first so that it is plotted below the spectrograph data
  prepped_data = [prepped_asi_images, prepped_spect_images]
  prepped_skymaps = [prepped_asi_skymaps, prepped_spect_skymaps]
  
  ; Set up a plotting window with a map projection
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
  
  ; Define scaling bounds for image data AND spectrograph data- in this case we just use an array to scale all sites
  ; the same - alternatively, one can use a hash to scale images on a per-site basis
  img_scale = [10, 105]
  spect_scale = [0, 7500] ; in Rayleighs, for whichever emission we are plotting (greenline in this example)
  
  ; Plot some gridlines
  gridline_color = aurorax_get_decomposed_color([0, 0, 0])
  clats = [30, 40, 50, 60, 70, 80]
  clons = [200, 220, 240, 260, 280, 300, 320, 340]
  aurorax_mosaic_oplot, constant_lats = clats, constant_lons = clons, color = gridline_color, linestyle = 2

  ; The aurorax_mosaic_oplot routine also includes a /mag option, to overplot contours
  ; that are defined in geomagnetic (AACGM) coordinates
  magnetic_gridline_color = aurorax_get_decomposed_color([255, 179, 0])
  clats = [63, 77]
  aurorax_mosaic_oplot, constant_lats = clats, color = magnetic_gridline_color, linestyle = 0, thick = 6, /mag
  
  ; Call the plotting function
  aurorax_mosaic_plot, prepped_data, prepped_skymaps, '2021-03-13T09:40:15', intensity_scales=img_scale, spect_intensity_scales=spect_scale, colortable=[0,8]
  
  ; Let's manually create a quick colorbar for the spectrograph data
  w = window(dimensions=[100,300], /no_toolbar, margin=0)
  n_ticks = 5
  tickvals = []
  ticknames = []
  for i=0, n_ticks-1 do begin
    tickvals = [tickvals, 255.0*(i/(n_ticks-1.0))]
    ticknames = [ticknames, strcompress(string(fix(7500*(i/(n_ticks-1.0)))),/remove_all)]
  endfor

  c = colorbar(rgb_table=8, range=spect_scale, orientation=1, title="Spectrograph 557.7 nm Intensity (Rayleighs)", $
               position=[0.6,0.1,0.8,0.9], tickvalues=tickvals, tickname=ticknames)

end




  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  