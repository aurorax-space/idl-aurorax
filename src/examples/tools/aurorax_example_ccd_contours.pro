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

pro aurorax_example_ccd_contours
  ; -------------------------------------------
  ; Adding Georeferenced Contours to CCD Images
  ; -------------------------------------------
  ;
  ; There are a few functions that help display contour lines on top of individual ASI images (CCD coordinates),
  ; facilitated using the aurorax_ccd_contour() function. In the below sections, we'll have a look at the
  ; options available and the different things you can do with them.
  ;

  ; Load in a skymap that we want to reference for our contours
  date_time = '2023-02-24T06:15:00'
  d = aurorax_ucalgary_download_best_skymap('TREX_RGB_SKYMAP_IDLSAV', 'yknf', date_time)
  skymap_data = aurorax_ucalgary_read(d.dataset, d.filenames)
  skymap = skymap_data.data[0]

  ; Grab an image that the skymap corresponds to, just to plot some examples
  d = aurorax_ucalgary_download('TREX_RGB_RAW_NOMINAL', date_time, date_time, site_uid = 'yknf')
  img = aurorax_ucalgary_read(d.dataset, d.filenames)
  img = img.data[*, *, *, 0]

  ; Grab some colors for plotting
  device, decomposed = 1
  white = aurorax_get_decomposed_color([255, 255, 255])
  red = aurorax_get_decomposed_color([255, 0, 0])

  ; ==================================================================================
  ; == Lines of constant azimuth ==
  ; ==================================================================================
  window, 0, xsize = 553, ysize = 480, title = 'LINES OF CONSTANT AZIMUTH'
  tvscl, img, /true
  ; Iterate through some different azimuth angles
  for az = 0, 360, 30 do begin
    ; Obtain pixel coordinates of this line of constant azimuth
    ccd_coords = aurorax_ccd_contour(skymap, constant_azimuth = az)
    ccd_x = ccd_coords[*, 0]
    ccd_y = ccd_coords[*, 1]

    ; overplot the line in device coordinates
    plots, ccd_x, ccd_y, color = white, /device, thick = 2, linestyle = 2
  endfor

  ; ==================================================================================
  ; == Lines of constant elevation ==
  ; ==================================================================================
  window, 1, xsize = 553, ysize = 480, title = 'LINES OF CONSTANT ELEVATION'
  tvscl, img, /true
  ; Iterate through some different elevation angles
  for el = 5, 90, 10 do begin
    ; Obtain pixel coordinates of this line of constant elevation
    ccd_coords = aurorax_ccd_contour(skymap, constant_elevation = el)
    ccd_x = ccd_coords[*, 0]
    ccd_y = ccd_coords[*, 1]

    ; overplot the line in device coordinates
    plots, ccd_x, ccd_y, color = white, /device, thick = 2, linestyle = 2
  endfor

  ; ==================================================================================
  ; == Lines of constant lat/lon ==
  ; ==================================================================================
  window, 2, xsize = 553, ysize = 480, title = 'LINES OF CONSTANT LAT/LON AND CUSTOM CONTOUR'
  tvscl, img, /true
  ; Iterate through some different latitudes
  for lat = 62, 63 do begin
    ; Obtain pixel coordinates of this line of constant latitude
    ccd_coords = aurorax_ccd_contour(skymap, constant_lat = lat)
    ccd_x = ccd_coords[*, 0]
    ccd_y = ccd_coords[*, 1]

    ; overplot the line in device coordinates
    plots, ccd_x, ccd_y, color = white, /device, thick = 2, linestyle = 2
  endfor

  ; Iterate through some different longitudes
  foreach lon, [-115, -114] do begin
    ; Obtain pixel coordinates of this line of constant longitude
    ccd_coords = aurorax_ccd_contour(skymap, constant_lon = lon)
    ccd_x = ccd_coords[*, 0]
    ccd_y = ccd_coords[*, 1]

    ; overplot the line in device coordinates
    plots, ccd_x, ccd_y, color = white, /device, thick = 2, linestyle = 2
  endforeach

  ; ==================================================================================
  ; == Manually defined contours ==
  ; ==================================================================================
  ; manually define a contour using arrays of lats and lons. Here, we just do a small
  ; section of the line of latitide = 62 deg. Use the contour function to obtain the
  ; device coords. Then overplot in device coords.
  ccd_coords = aurorax_ccd_contour(skymap, contour_lats = [62, 62, 62, 62], contour_lons = [-115, -114.66, -114.33, -114])
  ccd_x = ccd_coords[*, 0]
  ccd_y = ccd_coords[*, 1]
  plots, ccd_x, ccd_y, color = red, /device, thick = 5
  
  ; ==================================================================================
  ; == Lines of constant geomagnetic (AACGM) lat/lon ==
  ; ==================================================================================
  window, 3, xsize = 553, ysize = 480, title = 'LINES OF CONSTANT GEOMAGNETIC LAT/LON'
  tvscl, img, /true
  ; Iterate through some different latitudes
  for mlat = 68, 69 do begin
    ; Obtain pixel coordinates of this line of constant geomagnetic latitude (/MAG keyword)
    ccd_coords = aurorax_ccd_contour(skymap, constant_lat = mlat, /mag)
    ccd_x = ccd_coords[*, 0]
    ccd_y = ccd_coords[*, 1]

    ; overplot the line in device coordinates
    plots, ccd_x, ccd_y, color = white, /device, thick = 2, linestyle = 2
  endfor

  ; Iterate through some different longitudes
  foreach mlon, [-53, -56] do begin
    ; Obtain pixel coordinates of this line of constant geomagnetic longitude (/MAG keyword)
    ccd_coords = aurorax_ccd_contour(skymap, constant_lon = mlon, /mag)
    ccd_x = ccd_coords[*, 0]
    ccd_y = ccd_coords[*, 1]

    ; overplot the line in device coordinates
    plots, ccd_x, ccd_y, color = white, /device, thick = 2, linestyle = 2
  endforeach
end