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

pro aurorax_example_plot_fovs
  ; IDL-AuroraX include tools for plotting an instrument's field of view at specific sites,
  ; across all site, or even for custom locations. Below are several examples of doing so
  
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
  map_continents, color = border_color, thick = border_thick
  
  ; First, it is simple given any lat/lon site location, to plot an ASI FOV
  ; for a camera at that location
  aurorax_fov_oplot, 55.0, -130.0, 110.0, thick=3, min_elevation=5, site_name="site", /label_site, label_color=aurorax_get_decomposed_color([255,0,0])
  
  ; You can also pass in multiple sites at once, and change the altitude that FOVs are mapped at
  aurorax_fov_oplot, [57.0, 62.5], [-118.0,-97.0], 230.0, thick=4, linestyle=1, site_name=["site2", "site3"], /label_site, color=aurorax_get_decomposed_color([0,160,0])
  
  ; Plotting FoVs for an actual instrument
  ;
  ; The aurorax_fov_oplot routine can be used in combination with aurorax_list_observatories()
  ; to easily create maps of instrument arrays
  
  ; First, create a new map
  land_color = aurorax_get_decomposed_color([186, 186, 186])
  water_color = aurorax_get_decomposed_color([64, 89, 120])
  border_color = aurorax_get_decomposed_color([0, 0, 0])
  border_thick = 2
  window_bg_color = aurorax_get_decomposed_color([0, 0, 0])
  map_bounds = [40, 220, 80, 290]
  ilon = 255
  ilat = 56
  window, 1, xsize = 600, ysize = 400, xpos = 600, ypos=0
  map_win_loc = [0., 0., 1., 1.]
  device, decomposed = 1
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, ilat, ilon, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, thick = border_thick
  
  ; Now, use aurorax_list_observatories to grab all THEMIS-ASI site locations
  all_themis_sites = aurorax_list_observatories('themis_asi')
  
  ; Parse the list returned by aurorax_list_observatories
  themis_lats = []
  themis_lons = []
  themis_uids = []
  foreach site, all_themis_sites do begin
    themis_uids = [themis_uids, site.uid]
    themis_lons = [themis_lons, site.geodetic_longitude]
    themis_lats = [themis_lats, site.geodetic_latitude]
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
  aurorax_fov_oplot, themis_lats, themis_lons, 110.0, thick=2, site_name=themis_uid
  xyouts, 0.02, 0.02, "THEMIS-ASI SITES", /normal, color=0, charthick=2
  
  
  ; This process can be repeated for any instrument array
  ;
  ; Let's do another example, using REGO instruments
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
  window, 2, xsize = 600, ysize = 400, xpos = 0, ypos=430
  map_win_loc = [0., 0., 1., 1.]
  device, decomposed = 1
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, ilat, ilon, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, thick = border_thick

  ; Now, use aurorax_list_observatories to grab all REGO site locations
  all_rego_sites = aurorax_list_observatories('rego')

  ; Parse the list returned by aurorax_list_observatories
  rego_lats = []
  rego_lons = []
  rego_uids = []
  foreach site, all_rego_sites do begin
    rego_uids = [rego_uids, site.uid]
    rego_lons = [rego_lons, site.geodetic_longitude]
    rego_lats = [rego_lats, site.geodetic_latitude]
  endforeach

  ; Plot some gridlines
  gridline_color = aurorax_get_decomposed_color([0, 0, 0])
  clats = [30, 40, 50, 60, 70, 80]
  clons = [200, 220, 240, 260, 280, 300, 320, 340]
  aurorax_mosaic_oplot, constant_lats = clats, constant_lons = clons, color = gridline_color, linestyle = 2
  
  ; Now, call the aurorax_fov_oplot procedure with the rego site information
  ;
  ; *** Since we are plotting REGO sites, we'll set the altitude_km parameter to 230.0
  ;     as this is a commonly assumed altitude of the 630.0 nm redline emission
  aurorax_fov_oplot, rego_lats, rego_lons, 230.0, thick=2, site_name=rego_uids, color=aurorax_get_decomposed_color([255,0,0]), /label_site
  xyouts, 0.02, 0.02, "REGO SITES", /normal, color=0, charthick=2
  
  
  ; Plotting spectrograph FOVs
  ;
  ; The aurorax_fov_oplot procedure also has the ability to plot the field-of-view
  ; of meridian scanning spectrographs, like those part of the TREx project.
  ; 
  ; As an example, let's plot the field of view of TREx RGB and TREx 
  ; Spectrographs on the same map
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
  window, 3, xsize = 600, ysize = 400, xpos = 600, ypos=430
  map_win_loc = [0., 0., 1., 1.]
  device, decomposed = 1
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, ilat, ilon, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, thick = border_thick

  ; Now, use aurorax_list_observatories to grab all TREx RGB site locations
  all_rgb_sites = aurorax_list_observatories('trex_rgb')

  ; Parse the list returned by aurorax_list_observatories
  rgb_lats = []
  rgb_lons = []
  rgb_uids = []
  foreach site, all_rgb_sites do begin
    rgb_uids = [rgb_uids, site.uid]
    rgb_lons = [rgb_lons, site.geodetic_longitude]
    rgb_lats = [rgb_lats, site.geodetic_latitude]
  endforeach

  ; Plot some gridlines
  gridline_color = aurorax_get_decomposed_color([0, 0, 0])
  clats = [30, 40, 50, 60, 70, 80]
  clons = [200, 220, 240, 260, 280, 300, 320, 340]
  aurorax_mosaic_oplot, constant_lats = clats, constant_lons = clons, color = gridline_color, linestyle = 2

  ; Now, call the aurorax_fov_oplot procedure with the rgb site information
  aurorax_fov_oplot, rgb_lats, rgb_lons, 110.0, thick=2, site_name=rgb_uids, color=aurorax_get_decomposed_color([0,255,0]), /label_site
  
  ; Now, repeat the process for TREx spectrograph
  all_spect_sites = aurorax_list_observatories('trex_spectrograph')

  ; Parse the list returned by aurorax_list_observatories
  spect_lats = []
  spect_lons = []
  spect_uids = []
  foreach site, all_spect_sites do begin
    spect_uids = [spect_uids, site.uid]
    spect_lons = [spect_lons, site.geodetic_longitude]
    spect_lats = [spect_lats, site.geodetic_latitude]
  endforeach

  ; Plot some gridlines
  gridline_color = aurorax_get_decomposed_color([0, 0, 0])
  clats = [30, 40, 50, 60, 70, 80]
  clons = [200, 220, 240, 260, 280, 300, 320, 340]
  aurorax_mosaic_oplot, constant_lats = clats, constant_lons = clons, color = gridline_color, linestyle = 2

  ; Now, call the aurorax_fov_oplot procedure with the spect site information
  ;
  ; *** Here, we use the /specotograph keyword
  yellow = aurorax_get_decomposed_color([255,255,0])
  aurorax_fov_oplot, spect_lats, spect_lons, 110.0, thick=2, site_name=spect_uids, color=yellow, /label_site, label_color=yellow, /spectrograph
  xyouts, 0.02, 0.02, "TREx RGB & SPECTROGRAPH FoV", /normal, color=0, charthick=2
end








