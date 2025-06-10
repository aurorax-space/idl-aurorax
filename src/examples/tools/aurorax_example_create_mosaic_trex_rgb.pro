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

pro aurorax_example_create_mosaic_trex_rgb
  ; ------------------------
  ; Creating TREx RGB Mosaic
  ; ------------------------
  ;
  ; Note:
  ; In general, before building a mosaic you'll want to verify what sites you should use by looking
  ; at the summary data. In this case, the summary data clearly shows that Fort Smith had a different
  ; color profile than the other RGB cameras. The data is still useable, however in multi-imager
  ; studies Fort Smith's instrument response cannot be directly intercompared with, for example Rabbit,
  ; because of the color offset. This was an operational issue at Fort Smith.
  ;
  ; For the event used in this crib sheet, it is far more advantageous to use Yellowknife which has
  ; singificant overlap with Fort Smith but did not have the color profile issue.
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

  ; Initialize list to hold image data and skymaps
  image_list = list()
  skymap_list = list()

  ; Date of Interest
  date_time = '2023-02-24T06:15:00'

  ; Iterate through sites we want to included in the mosaic
  foreach site, ['yknf', 'gill', 'rabb'] do begin
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
  map_continents, color = border_color, mlinethick = border_thick

  ; Define scaling bounds for image data - in this case we just use an array to scale all sites
  ; the same - alternatively, one can use a hash to scale images on a per-site basis
  scale = [10, 105]

  ; Pick which time within the prepared data that you'd like to plot
  ;
  ; Note that the mosaic plotting function in AuroraX will search for the timestamp in the prepared
  ; data that is *closest* and within one-minute to the requested timestamp.
  mosaic_dt = '2023-02-24T06:15:00'

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
  aurorax_mosaic_plot, prepped_images, prepped_skymaps, mosaic_dt, intensity_scales = scale

  ; Overplot some text
  !p.font = 1
  device, set_font = 'Helvetica Bold', /tt_font, set_character_size = [7, 7]
  xyouts, 0.01, 0.9, 'TREx RGB', /normal, font = 1, charsize = 6
  xyouts, 0.01, 0.085, strmid(image_data.timestamp[0], 0, 10), /normal, font = 1, charsize = 5
  xyouts, 0.01, 0.01, strmid(image_data.timestamp[0], 11, 8) + ' UTC', /normal, font = 1, charsize = 5
  !p.font = -1
end
