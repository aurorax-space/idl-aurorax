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

pro aurorax_example_ephemeris_multi_oplot_mosaic
  ; --------------------------------------------------
  ; Creating Mosaic with Multiple Satellite Footprints
  ; --------------------------------------------------
  ;
  ; Note:
  ; For more information on the actual procedure of making a mosaic, see one of the
  ; normal mosaic crib sheets (e.g. aurorax_example_create_mosaic_themis.pro)
  ;
  ; Combining IDL-AuroraX's mosaic tools with it's ephemeris search capababilities
  ; make it straightforward to map satellite locations over a mosaic.
  ;
  ; The belor crib sheet provides an example of doing so - the below code and comments
  ; walk through the process of obtaining the footprints of two Swarm spacecraft, creating
  ; a mosaic, and mapping Swarm's overflight on top of the mosaic.
  ;

  ; Timestamp for the mosaic
  mosaic_timestamp = '2023-02-24T07:05:00'

  ; Lets grab 20 minutes of Swarm A footprint data
  start_t = '2023-02-24T06:55:00'
  end_t = '2023-02-24T07:15:00'
  program = 'swarm'
  platforms = ['swarma', 'swarmc']
  instrument_type = 'footprint'

  ; Search for ephemeris data
  response = aurorax_ephemeris_search(start_t, end_t, programs = program, platforms = platforms, instrument_types = instrument_type)
  ephemeris_data = response.data

  ; Create arrays of lats and lons of footprint for all timestamps
  ; e will also extract the exact location of the spacecraft in our mosaic
  swarm_a_lats = []
  swarm_a_lons = []
  swarm_c_lats = []
  swarm_c_lons = []
  for i = 0, n_elements(ephemeris_data) - 1 do begin
    ; Add lat/lon to the proper arrays by checking the platform field of each element
    if (ephemeris_data[i].data_source).platform eq 'swarma' then begin
      ; if this iteration is Swarm A
      swarm_a_lats = [swarm_a_lats, (ephemeris_data[i].location_geo).lat]
      swarm_a_lons = [swarm_a_lons, (ephemeris_data[i].location_geo).lon]

      ; Extract location of spacecraft if it matches our mosaic's timestamp
      if ephemeris_data[i].epoch eq mosaic_timestamp then begin
        swarm_a_conjunction_lon = (ephemeris_data[i].location_geo).lon
        swarm_a_conjunction_lat = (ephemeris_data[i].location_geo).lat
      endif
    endif else if (ephemeris_data[i].data_source).platform eq 'swarmc' then begin
      ; if this iteration is Swarm C
      swarm_c_lats = [swarm_c_lats, (ephemeris_data[i].location_geo).lat]
      swarm_c_lons = [swarm_c_lons, (ephemeris_data[i].location_geo).lon]

      ; Extract location of spacecraft if it matches our mosaic's timestamp
      if ephemeris_data[i].epoch eq mosaic_timestamp then begin
        swarm_c_conjunction_lon = (ephemeris_data[i].location_geo).lon
        swarm_c_conjunction_lat = (ephemeris_data[i].location_geo).lat
      endif
    endif
  endfor

  ; Now, let's construct a mosaic for a time within the overflight timeframe

  ; Initialize list to hold image data and skymaps
  image_list = list()
  skymap_list = list()

  ; Iterate through sites we want to included in the mosaic
  foreach site, ['yknf', 'gill', 'rabb'] do begin
    ; download and read image data for this site and add to list
    d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', mosaic_timestamp, mosaic_timestamp, site_uid = site)
    image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    image_list.add, image_data

    ; download and read the correct skymap for this site and add to list
    d = aurorax_ucalgary_download_best_skymap('TREX_RGB_SKYMAP_IDLSAV', site, mosaic_timestamp)
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

  ; Timestamp within mosaic data to plot for
  mosaic_dt = '2023-02-24T07:05:00'

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

  ; Overplot the Swarm A and Swarm C footprints
  swarm_a_color = aurorax_get_decomposed_color([255, 0, 0])
  swarm_c_color = aurorax_get_decomposed_color([0, 0, 255])
  plots, swarm_a_lons, swarm_a_lats, color = swarm_a_color, linestyle = 0, thick = 3
  plots, swarm_c_lons, swarm_c_lats, color = swarm_c_color, linestyle = 0, thick = 3

  ; Overplot the location of the Swarm spacecrafts in this mosaic as a point
  aurorax_mosaic_oplot, point = [swarm_a_conjunction_lon, swarm_a_conjunction_lat], color = swarm_a_color, symsize = 2
  aurorax_mosaic_oplot, point = [swarm_c_conjunction_lon, swarm_c_conjunction_lat], color = swarm_c_color, symsize = 2

  !p.font = 1
  ; Add a label for the spacecraft
  xyouts, 0.24, 0.55, 'Swarm A', color = swarm_a_color, /normal, font = 1, charsize = 2
  xyouts, 0.22, 0.51, 'Swarm C', color = swarm_c_color, /normal, font = 1, charsize = 2

  ; Plot some text on top
  xyouts, 0.01, 0.9, 'TREx RGB', /normal, font = 1, charsize = 6
  xyouts, 0.01, 0.085, strmid(image_data.timestamp[0], 0, 10), /normal, font = 1, charsize = 5
  xyouts, 0.01, 0.01, strmid(image_data.timestamp[0], 11, 8) + ' UTC', /normal, font = 1, charsize = 5
  !p.font = -1
end
