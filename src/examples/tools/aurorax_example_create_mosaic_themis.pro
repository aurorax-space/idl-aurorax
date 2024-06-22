;-------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;-------------------------------------------------------------

pro aurorax_example_create_mosaic_themis

  ; Create lists to hold all image data and skymap structures
  data_list = list()
  skymap_list = list()

  ; Date of Interest
  date_time = '2021-11-04T09:30:00'

  ; Date to search back to for skymaps
  earliest_date_time = '2017-02-24T06:15:00'

  foreach site, ["atha", "fsmi", "fsim", "pina", "talo", "tpas"] do begin
    ; download and read data for this site, then add to respective list
    d = aurorax_ucalgary_download('THEMIS_ASI_RAW', date_time, date_time, site_uid=site)
    image_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    data_list.add, image_data

    ; download all skymaps in range, read them in, then append *most recent* to respective list
    d = aurorax_ucalgary_download('THEMIS_ASI_SKYMAP_IDLSAV', earliest_date_time, date_time, site_uid=site)
    skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
    skymap_list.add, skymap_data.data[-1]
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

  map_bounds = [40,220,80,290]
  ilon = 255 & ilat = 56

  window, 0, xsize=800, ysize=600, xpos=0
  map_win_loc = [0., 0., 1., 1.]
  device, decomposed=1
  polyfill, [0.,0.,1.,1.], [0.,1.,1.,0.], color=window_bg_color, /normal
  polyfill, [map_win_loc[0],map_win_loc[2],map_win_loc[2],map_win_loc[0]], [map_win_loc[1],map_win_loc[1],map_win_loc[3],map_win_loc[3]], color=water_color, /normal
  map_set, ilat, ilon, 0, sat_p=[20,0,0], /satellite, limit=map_bounds, position=map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color=land_color
  map_continents, color=border_color, thick=border_thick

  ; Define scaling bounds for image data if desiresd
  scale = hash("atha", [2500, 10000],$
    "fsmi", [2500, 10000],$
    "fsim", [2500, 12500],$
    "pina", [2500, 10000],$
    "talo", [2000, 10000],$
    "tpas", [2500, 10000])

  ; Plot the first frame
  image_idx = 0

  ; Use grey colormap for themis
  ct = 0

  ; Plot some gridlines
  gridline_color = aurorax_get_decomposed_color([0, 0, 0])
  clats = [30,40,50,60,70,80]
  clons = [200,220,240,260,280,300,320,340]
  aurorax_mosaic_oplot, constant_lats=clats , constant_lons=clons, color=gridline_color, linestyle=2, thick=2

  ; Call the mosaic creation function to plot the mosaic in the current window
  aurorax_mosaic_plot, prepped_data, prepped_skymap, image_idx, intensity_scales=scale, colortable=ct

  ; Plot some text on top
  xyouts, 0.01, 0.9, "THEMIS ASI", /normal, font=1, charsize=6
  xyouts, 0.01, 0.085, strmid(image_data.timestamp[0],0,10), /normal, font=1, charsize=5
  xyouts, 0.01, 0.01, strmid(image_data.timestamp[0],11,8)+" UTC", /normal, font=1, charsize=5
end

