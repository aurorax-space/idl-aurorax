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

pro aurorax_example_create_mosaic_themis
  ; ----------------------
  ; Creating THEMIS Mosaic
  ; ----------------------
  ;
  ; The process of making a mosaic involves properly accounting for the mapping of each pixel. Due
  ; to the fisheye optics, the pixels become increasingly large as you move away from zenith, to
  ; lower elevation angles.
  ;
  ; Our methodology for creating mosaics relies on two key points.
  ;
  ; 1. We must accurately account for the changing (and unique) pixel areas and locations in geodetic
  ; coordinates, and when putting multiple imagers together, we want to use the information from
  ; the closest camera
  ; 2. Our methodology involves creating exact polygons for each pixel (this is why the skymap
  ; contains the pixel corners!), for each camera and filling those polygons with the correct
  ; (scaled, or calibrated) imager data. This methodology ensures accuracy of all pixels within
  ; the FoV.
  ;
  ; The procedure for making a mosaic is best done in 1D vector space. Below you will find functions
  ; that convert the skymaps and images to vectors, before plotting those vectors.
  ;

  ; Create lists to hold all image data and skymap structures
  data_list = list()
  skymap_list = list()

  ; Date of Interest
  date_time = '2021-11-04T09:30:00'

  foreach site, ['atha', 'fsmi', 'fsim', 'pina', 'talo', 'tpas'] do begin
    ; download and read data for this site, then add to respective list
    d = aurorax_ucalgary_download('THEMIS_ASI_RAW', date_time, date_time, site_uid = site)
    image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    data_list.add, image_data

    ; download all skymaps in range, read them in, then append *most recent* to respective list
    d = aurorax_ucalgary_download_best_skymap('THEMIS_ASI_SKYMAP_IDLSAV', site, date_time)
    skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    skymap = skymap_data.data[0]
    skymap_list.add, skymap
  endforeach

  ; set altitude in km
  altitude = 115

  ; Prep the images and skymaps for plotting
  prepped_data = aurorax_mosaic_prep_images(data_list)
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
  map_continents, color = border_color, mlinethick = border_thick

  ; Define scaling bounds for image data if desiresd
  scale = hash('atha', [2500, 10000], $
    'fsmi', [2500, 10000], $
    'fsim', [2500, 12500], $
    'pina', [2500, 10000], $
    'talo', [2000, 10000], $
    'tpas', [2500, 10000])

  ; Pick which time within the prepared data that you'd like to plot
  mosaic_dt = '2021-11-04T09:30:00'

  ; Use grey colormap for themis
  ct = 0

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

  ; Call the mosaic creation function to plot the mosaic in the current window
  aurorax_mosaic_plot, prepped_data, prepped_skymap, mosaic_dt, intensity_scales = scale, colortable = ct

  ; Overplot some text
  !p.font = 1
  device, set_font = 'Helvetica Bold', /tt_font, set_character_size = [7, 7]
  xyouts, 0.01, 0.9, 'THEMIS ASI', /normal, font = 1, charsize = 6
  xyouts, 0.01, 0.085, strmid(image_data.timestamp[0], 0, 10), /normal, font = 1, charsize = 5
  xyouts, 0.01, 0.01, strmid(image_data.timestamp[0], 11, 8) + ' UTC', /normal, font = 1, charsize = 5
  !p.font = -1
end
