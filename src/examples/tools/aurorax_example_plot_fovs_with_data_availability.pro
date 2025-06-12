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

pro aurorax_example_plot_fovs_with_data_availability
  ; --------------------------------------------------------------
  ; Creating Maps of Instrument FOVs for sites with available data
  ; --------------------------------------------------------------
  ;
  ; IDL-AuroraX include tools for plotting an instrument's field of view at specific sites,
  ; across all site, or even for custom locations. For more information on the functionality
  ; itself, refer to the crib sheet: 'aurorax_example_plot_fovs'
  ;
  ; It can be helpful to create a map of instrument FOVs, but only including
  ; FOVs for sites that actually have available data in some time range. This
  ; crib sheet walks through an example of how you can achieve this using
  ; IDL-AuroraX tools.
  ;

  ; First, we need to create a direct graphics map that the data can be plotted
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
  window, 0, xsize = 600, ysize = 400, xpos = 0
  map_win_loc = [0., 0., 1., 1.]
  device, decomposed = 1
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, ilat, ilon, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, mlinethick = border_thick

  ; ---------------------------
  ; Plotting FoVs for SMILE ASI
  ;
  ; The aurorax_fov_oplot routine can be used in combination with aurorax_list_observatories()
  ; to easily create maps of instrument arrays. Let's first make a map of all SMILE ASI FOVS,
  ; without worrying about data availability.
  ;

  ; First, create a new map
  land_color = aurorax_get_decomposed_color([186, 186, 186])
  water_color = aurorax_get_decomposed_color([64, 89, 120])
  border_color = aurorax_get_decomposed_color([0, 0, 0])
  border_thick = 2
  window_bg_color = aurorax_get_decomposed_color([0, 0, 0])
  map_bounds = [40, 220, 80, 290]
  ilon = 255
  ilat = 56
  window, 0, xsize = 600, ysize = 400, xpos = 0, ypos = 0
  map_win_loc = [0., 0., 1., 1.]
  device, decomposed = 1
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, ilat, ilon, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, mlinethick = border_thick

  ; Now, use aurorax_list_observatories to grab all SMILE-ASI site locations
  all_themis_sites = aurorax_list_observatories('smile_asi')

  ; Parse the list returned by aurorax_list_observatories
  smile_lats = []
  smile_lons = []
  smile_uids = []
  foreach site, all_themis_sites do begin
    smile_uids = [smile_uids, site.uid]
    smile_lons = [smile_lons, site.geodetic_longitude]
    smile_lats = [smile_lats, site.geodetic_latitude]
  endforeach

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

  ; Now, call the aurorax_fov_oplot procedure with the themis site information
  aurorax_fov_oplot, smile_lats, smile_lons, 110.0, thick = 2, site_name = smile_uids

  ; Add a label for the map
  !p.font = 1
  xyouts, 0.02, 0.02, 'SMILE-ASI SITES', /normal, color = 0, charthick = 2, charsize = 2.5
  !p.font = -1
  
  ;---------------------------------------------------
  ; Plotting FoVs for SMILE ASI with Data Availability
  ;
  ; Now, with some slight alterations to the above procedure, we
  ; can make the same map, but omit any sites that don't have
  ; data for some particular time range
  ;
  
  ; First, let's define a timestamp range for which we are interested in
  ; plotting FOVs for. Instrument FOVs will only be plotted if there is
  ; data within this timerange.
  data_available_start_dt = '2024-11-15T00:00:00'
  data_available_end_dt = '2024-11-15T23:59:59'

  ; Now, create a new map
  land_color = aurorax_get_decomposed_color([186, 186, 186])
  water_color = aurorax_get_decomposed_color([64, 89, 120])
  border_color = aurorax_get_decomposed_color([0, 0, 0])
  border_thick = 2
  window_bg_color = aurorax_get_decomposed_color([0, 0, 0])
  map_bounds = [40, 220, 80, 290]
  ilon = 255
  ilat = 56
  window, 1, xsize = 600, ysize = 400, xpos = 600, ypos = 0
  map_win_loc = [0., 0., 1., 1.]
  device, decomposed = 1
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, ilat, ilon, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, mlinethick = border_thick

  ; Now, use aurorax_list_observatories to grab all SMILE-ASI site locations
  all_themis_sites = aurorax_list_observatories('smile_asi')

  ; Parse the list returned by aurorax_list_observatories
  smile_lats = []
  smile_lons = []
  smile_uids = []
  foreach site, all_themis_sites do begin
    
    ; Using IDL-AuroraX's `aurorax_ucalgary_get_urls()` function, we can search
    ; for data within our desired time range, for each site.
    ;
    ; Let's just look for sites that have raw data for this example - one could
    ; filter based on a different dataset if desired
    urls_available = aurorax_ucalgary_get_urls('SMILE_ASI_RAW', data_available_start_dt, data_available_end_dt, site_uid = site.uid)
    
    ; If there are no URLs available (no data available) we skip adding this site altogether
    if urls_available.count eq 0 then continue
    
    ; Continue the procedure as normal
    smile_uids = [smile_uids, site.uid]
    smile_lons = [smile_lons, site.geodetic_longitude]
    smile_lats = [smile_lats, site.geodetic_latitude]
  endforeach

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

  ; Now, call the aurorax_fov_oplot procedure with the themis site information
  aurorax_fov_oplot, smile_lats, smile_lons, 110.0, thick = 2, site_name = smile_uids

  ; Add a label for the map
  !p.font = 1
  xyouts, 0.02, 0.02, 'SMILE-ASI SITES WITH DATA ON 2024-11-15', /normal, color = 0, charthick = 2, charsize = 2.5
  !p.font = -1

end
