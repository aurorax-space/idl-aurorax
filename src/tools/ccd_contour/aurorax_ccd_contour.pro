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

;+
; :Description:
;       Obtain the CCD coordinates of a variety of different contours, given one of a
;       constant elevation, azimuth, geo or mag lat or lon, or arrays of lats/lons defining
;       a contour. Used for plotting on top of an image.
;
;       This function returns an array of shape (N,2), which are the x and y CCD coordinates
;       of the contour
;
; :Parameters:
;       skymap: in, required, Struct
;         the skymap to use for georeferencing
;
; :Keywords:
;       constant_azimuth: in, optional, Boolean
;         the desired constant azimuth, in degrees from north, to obtain contour for
;       constant_elevation: in, optional, Integer or Float
;         the desired constant elevation to obtain contour for
;       constant_lat: in, optional, Integer or Float
;         the desired constant latitude to obtain contour for
;       constant_lon: in, optional, Integer or Float
;         the desired constant longitude to obtain contour for
;       contour_lats: in, optional, Array
;         array of lats defining a contour
;       contour_lons: in, optional, Array
;         array of lons defining a contour
;       altitude_km: in, optional, Integer
;         the altitude of the image data for georeferencing if necessary
;
; :Keywords:
;       mag: in, optional, Boolean
;         use this keyword if lats/lons are supplied in magnetic coordinates
;
; :Returns:
;       Array
;
; :Examples:
;       contour = aurorax_ccd_contour(skymap, constant_lat = 67)
;       ccd_x = contour[*,0]
;       ccd_y = contour[*,1]
;+
function aurorax_ccd_contour, $
  skymap, $
  constant_azimuth = constant_azimuth, $
  constant_elevation = constant_elevation, $
  constant_lat = constant_lat, $
  constant_lon = constant_lon, $
  contour_lats = contour_lats, $
  contour_lons = contour_lons, $
  altitude_km = altitude_km, $
  mag = mag
  compile_opt idl2

  ; Check that both lat/lon are provided for custom contour
  if isa(contour_lats) + isa(contour_lons) eq 1 then begin
    print, '[aurorax_ccd_contour] Error: When manually providing a contour, contour_lats & contour_lons must both be provided.'
    return, !null
  endif

  ; Check that at least one contour is provided
  if isa(constant_azimuth) + isa(constant_elevation) + isa(constant_lat) + isa(constant_lon) + isa(contour_lats) eq 0 then begin
    print, '[aurorax_ccd_contour] Error: No contour provided in input.'
    return, !null
  endif

  ; Check that no more than one contour is provided
  if isa(constant_azimuth) + isa(constant_elevation) + isa(constant_lat) + isa(constant_lon) + isa(contour_lats) gt 1 then begin
    print, '[aurorax_ccd_contour] Error: Only one contour may be provided per call.'
    return, !null
  endif

  ; If contour is defined in lat/lon space, check that an altitude is provided. If not, default to middle.
  if isa(constant_lat) or isa(constant_lon) or isa(contour_lats) then begin
    if not isa(altitude_km) then begin
      ; Select middle altitude from skymap
      altitude_km = skymap.full_map_altitude[1] / 1000.0
    endif
  endif

  ; First handling the case of a contour of constant azimuth
  if isa(constant_azimuth) then begin
    if not isa(constant_azimuth, /scalar) then begin
      print, '[aurorax_ccd_contour] Error: constant_azimuth must be a scalar.'
    endif

    ; check that azimuth is valid
    if constant_azimuth lt 0 or constant_azimuth gt 360 then begin
      print, '[aurorax_ccd_contour] Error: constant_azimuth must be in the range (0,360).'
    endif
    if constant_azimuth eq 360 then const_az = 0 else const_az = constant_azimuth

    ; pull az and el arrays from skymap
    azimuth = skymap.full_azimuth
    elevation = skymap.full_elevation

    ; iterate through elevation array in steps
    x_list = []
    y_list = []
    for el_min = 5, 89, 3 do begin
      ; get indices of this elevation slice
      el_max = el_min + 3

      ; Get index of closest azimuth, within this elevation slice
      flattened_az = reform(azimuth, (size(azimuth, /dimensions))[0] * (size(azimuth, /dimensions))[1])
      flattened_el = reform(elevation, (size(elevation, /dimensions))[0] * (size(elevation, /dimensions))[1])

      flat_slice_idx = where(abs(flattened_az[where(flattened_el ge el_min and flattened_el lt el_max)] - const_az) eq $
        min(abs(flattened_az[where(flattened_el ge el_min and flattened_el lt el_max)] - const_az), /nan), /null)
      if flat_slice_idx eq !null then continue
      flat_slice_az = ((flattened_az[where(flattened_el ge el_min and flattened_el lt el_max)])[flat_slice_idx])[0]
      flat_idx = where(flattened_el ge el_min and flattened_el lt el_max and flattened_az eq flat_slice_az, /null)

      if flat_idx eq !null then continue

      ; Append this point to the x,y arrays
      x_list = [x_list, (array_indices(azimuth, flat_idx))[0]]
      y_list = [y_list, (array_indices(azimuth, flat_idx))[1]]
    endfor

    return, [[x_list], [y_list]]
  endif

  ; Next handling the case of a contour of constant elevation
  if isa(constant_elevation) then begin
    if not isa(constant_elevation, /scalar) then begin
      print, '[aurorax_ccd_contour] Error: constant_elevation must be a scalar.'
    endif

    ; check that elevation is valid
    if constant_elevation lt 0 or constant_elevation gt 90 then begin
      print, '[aurorax_ccd_contour] Error: constant_elevation must be in the range (0,90).'
    endif

    ; pull az and el arrays from skymap
    azimuth = skymap.full_azimuth
    elevation = skymap.full_elevation

    ; In the case that the user requests 90 degrees, return the single closest pixel
    if constant_elevation eq 90 then begin
      idx_90 = array_indices(elevation, where(elevation eq max(elevation, /nan)))
      return, [[idx_90[0]], [idx_90[1]]]
    endif

    ; iterate through azimuth array in steps
    x_list = []
    y_list = []
    for az_min = 0, 359, 5 do begin
      ; get indices of this elevation slice
      az_max = az_min + 5

      ; Get index of closest elevation, within this azimuth slice
      flattened_az = reform(azimuth, (size(azimuth, /dimensions))[0] * (size(azimuth, /dimensions))[1])
      flattened_el = reform(elevation, (size(elevation, /dimensions))[0] * (size(elevation, /dimensions))[1])

      flat_slice_idx = where(abs(flattened_el[where(flattened_az ge az_min and flattened_az le az_max)] - constant_elevation) eq $
        min(abs(flattened_el[where(flattened_az ge az_min and flattened_az le az_max)] - constant_elevation), /nan), /null)
      if flat_slice_idx eq !null then continue
      flat_slice_el = ((flattened_el[where(flattened_az ge az_min and flattened_az le az_max)])[flat_slice_idx])[0]
      flat_idx = where(flattened_az ge az_min and flattened_az le az_max and flattened_el eq flat_slice_el, /null)

      if flat_idx eq !null then continue

      ; Append this point to the x,y arrays
      x_list = [x_list, (array_indices(elevation, flat_idx))[0]]
      y_list = [y_list, (array_indices(elevation, flat_idx))[1]]
    endfor

    ; close the circle
    x_list = [x_list, x_list[0]]
    y_list = [y_list, y_list[0]]

    return, [[x_list], [y_list]]
  endif

  ; Next handling case of lines of constant lat
  if isa(constant_lat) then begin
    if not isa(constant_lat, /scalar) then begin
      print, '[aurorax_ccd_contour] Error: constant_lat must be a scalar.'
    endif

    ; check that latitude is valid
    if constant_lat lt -90 or constant_lat gt 90 then begin
      print, '[aurorax_ccd_contour] Error: constant_lat must be in the range (-90,90).'
    endif

    ; grab necessary data from skymap
    lons = skymap.full_map_longitude
    lons[where(lons gt 180)] -= 360

    ; Take min/max lon to be mean +/- 20 degrees
    min_skymap_lon = mean(lons, /nan) - 15
    max_skymap_lon = mean(lons, /nan) + 15

    n_points = 50
    contour_lats = replicate(constant_lat, n_points)
    contour_lons = findgen(n_points, increment = (max_skymap_lon - min_skymap_lon) / n_points, start = min_skymap_lon)
    result = __convert_lonlat_to_ccd(contour_lons, contour_lats, skymap, altitude_km)
    x_list = result[0]
    y_list = result[1]

    return, [[x_list], [y_list]]
  endif

  ; Next handling case of lines of constant lon
  if isa(constant_lon) then begin
    if not isa(constant_lon, /scalar) then begin
      print, '[aurorax_ccd_contour] Error: constant_lon must be a scalar.'
    endif

    ; check that latitude is valid
    if constant_lon lt -180 or constant_lon gt 180 then begin
      print, '[aurorax_ccd_contour] Error: constant_lon must be in the range (-180,180).'
    endif

    ; grab necessary data from skymap
    lats = skymap.full_map_latitude

    min_skymap_lat = mean(lats, /nan) - 5
    max_skymap_lat = mean(lats, /nan) + 5

    ; Convert lat/lons to CCD coordinates
    n_points = 50
    contour_lons = replicate(constant_lon, n_points)
    contour_lats = findgen(n_points, increment = (max_skymap_lat - min_skymap_lat) / n_points, start = min_skymap_lat)
    result = __convert_lonlat_to_ccd(contour_lons, contour_lats, skymap, altitude_km)
    x_list = result[0]
    y_list = result[1]

    result = [[x_list], [y_list]]
    if result eq !null then begin
      print, '[aurorax_ccd_contour] Error: could not obtain any CCD coordinates within provided skymap. Please ensure ' + $
        'that valid coordinates for this skymap are being used.'
    endif else return, result
  endif

  ; Finally handling case of custom lats and lons
  if isa(contour_lats) then begin
    ; Convert lat/lons to CCD coordinates
    result = __convert_lonlat_to_ccd(contour_lons, contour_lats, skymap, altitude_km)
    x_list = result[0]
    y_list = result[1]

    result = [[x_list], [y_list]]
    if result eq !null then begin
      print, '[aurorax_ccd_contour] Error: could not obtain any CCD coordinates within provided skymap. Please ensure ' + $
        'that valid coordinates for this skymap are being used.'
    endif else return, result
  endif
end
