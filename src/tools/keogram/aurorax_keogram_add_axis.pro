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
;       Add one or more desired physical axes to a keogram structure, which is
;       usually obtained via aurorax_keogram_create. Options are elevation, and
;       geographic/magnetic lats (lons for ewograms).
;
;       This function returns a keogram structure containing the new axes.
;
; :Parameters:
;       keogram_struct: in, required, Struct
;         keogram structure - usually the return value of aurorax_keogram_create()
;       skymap: in, required, Struct
;         the skymap to use for georeferencing
;
; :Keywords:
;       altitude_km: in, optional, Integer or Float
;         altitude, in kilometers, of the keogram data
;       geo: in, optional, Boolean
;         adds an axis of geographic coordinates
;       mag: in, optional, Boolean
;         adds an axis of geomagnetic coordinates
;       elev: in, optional, Boolean
;         adds an axis of elevation angles
;       aacgm_date: in, optioinal, String
;         a date string in the format 'YYYY-MM-DD' specifying the date to use for AACGM
;         coordinate transformations
;       aacgm_height: in, optional, String
;         input altitude (km) for geomagnetic (AACGM) coordinate transformations - if
;         not supplied, default is 0.0
;
; :Returns:
;       Struct
;
; :Examples:
;       keo = aurorax_keogram_add_axis(keo, skymap, /geo, /elev, altitude_km=110)
;+
function aurorax_keogram_add_axis, $
  keogram_struct, $
  skymap, $
  altitude_km = altitude_km, $
  geo = geo, $
  mag = mag, $
  elev = elev, $
  aacgm_date = aacgm_date, $
  aacgm_height = aacgm_height
  
  if keyword_set(geo) and not keyword_set(altitude_km) then begin
    print, '[aurorax_keogram_add_axis] Error: Using ''/geo'' or ''/mag'' requires passing in ''altitude_km''.'
    return, !null
  endif

  ; Determine number of channels and height of keogram
  time_stamp = keogram_struct.timestamp
  keo_arr = keogram_struct.data
  if n_elements(size(keo_arr, /dimensions)) eq 3 then begin
    n_channels = (size(keo_arr, /dimensions))[0]
    keo_height = (size(keo_arr, /dimensions))[2]
  endif else if n_elements(size(keo_arr, /dimensions)) eq 2 then begin
    n_channels = 1
    keo_height = (size(keo_arr, /dimensions))[1]
  endif

  ; Check that at least one keyword is passed
  if not keyword_set(geo) and not keyword_set(mag) and not keyword_set(geo) then begin
    print, '[aurorax_keogram_add_axis] Error: At least one of ''/geo'', ''/mag'', ''/elev'', must be set to add axes.'''
    return, !null
  endif
  
  ; If date is supplied for magnetic transformations, check correct format
  if keyword_set(aacgm_date) then begin
    if ~isa(aacgm_date, /string, /scalar) then begin
      print, '[aurorax_bounding_box_extract_metric] Error: keyword ''aacgm_date'' should be a scalar string in the format "YYYY-MM-DD"'
      return, !null
    endif
    if (strlen(aacgm_date) ne 10) or (strmid(aacgm_date,4,1) ne '-') or (strmid(aacgm_date,7,1) ne '-') then begin
      print, '[aurorax_bounding_box_extract_metric] Error: keyword ''aacgm_date'' should be a scalar string in the format "YYYY-MM-DD"'
      return, !null
    endif
  endif

  ; set default height for aacgm transformations if not supplied
  if ~ keyword_set(aacgm_height) then begin
    aacgm_height = 0.0
  endif
  
  ; Check that skymap size matches keogram
  if keogram_struct.instrument_type eq 'asi' then begin
    if keogram_struct.axis eq 0 then begin
      if (size(skymap.full_azimuth, /dimensions))[1] ne keo_height then begin
        print, '[aurorax_keogram_add_axis] Error: Skymap size does not match size of'
        return, !null
      endif
    endif else begin
      if (size(skymap.full_azimuth, /dimensions))[0] ne keo_height then begin
        print, '[aurorax_keogram_add_axis] Error: Skymap size does not match size of'
        return, !null
      endif
    endelse
  endif else if keogram_struct.instrument_type eq 'spectrograph' then begin
    if keogram_struct.axis eq 0 then begin
      if (size(skymap.full_elevation, /dimensions))[0] ne keo_height then begin
        print, '[aurorax_keogram_add_axis] Error: Skymap size does not match size of'
        return, !null
      endif
    endif
  endif

  ; Obtain keogram index in CCD coords
  slice_idx = keogram_struct.slice_idx

  ; grab necessary data from skymap
  altitudes = skymap.full_map_altitude
  lats = skymap.full_map_latitude
  lons = skymap.full_map_longitude
  lons[where(lons gt 180)] -= 360
  elevation = skymap.full_elevation
  
  ; Reform arrays for spectrograph so we can use the same indexing logic as for ASIs
  if keogram_struct.instrument_type eq 'spectrograph' then begin
    lats = reform(lats, [1, size(lats, /dimensions)])
    lons = reform(lons, [1, size(lons, /dimensions)])
    elevation = reform(elevation, [1, size(elevation, /dimensions)])
  endif
  
  ; grab ccd axis
  ccd_y = keogram_struct.ccd_y

  ; Create elevation axis
  elev_y = []
  foreach row_idx, keogram_struct.ccd_y do begin
    if keogram_struct.axis eq 0 then begin
      el = elevation[slice_idx, row_idx]
    endif else begin
      el = elevation[row_idx, slice_idx]
    endelse
    elev_y = [elev_y, el]
  endforeach

  ; Convert altitudes to km for interpolation
  interp_alts = altitudes / 1000.

  if where(float(altitude_km) eq interp_alts, /null) ne !null then begin
    ; no interpolation required
    alt_idx = where(float(altitude_km) eq interp_alts, /null)

    ; Grab all latitudes
    geo_y = []
    foreach row_idx, keogram_struct.ccd_y do begin
      if keogram_struct.axis eq 0 then begin
        lat = lats[slice_idx, row_idx, alt_idx]
        geo_y = [geo_y, lat]
      endif else begin
        lon = lons[row_idx, slice_idx, alt_idx]
        geo_y = [geo_y, lon]
      endelse
    endforeach
  endif else begin
    ; interpolation is required
    ; first check if supplied altitude is valid for interpolation
    if (altitude_km lt min(interp_alts)) or (altitude_km gt max(interp_alts)) then begin
      error_msg = '[aurorax_keogram_add_axis] Error: Altitude of ' + strcompress(string(altitude_km), /remove_all) + ' km is outside the valid ' + $
        'range of [' + strcompress(string(min(interp_alts)), /remove_all) + ',' + strcompress(string(max(interp_alts)), /remove_all) + '] km.'
      print, error_msg
      return, !null
    endif
    
    ; Interpolate all latitudes
    geo_y = []
    foreach row_idx, keogram_struct.ccd_y do begin
      if keogram_struct.axis eq 0 then begin
        lat = interpol(reform(lats[slice_idx, row_idx, *]), interp_alts, altitude_km)
        geo_y = [geo_y, lat]
      endif else begin
        lon = interpol(reform(lons[row_idx, slice_idx, *]), interp_alts, altitude_km)
        geo_y = [geo_y, lon]
      endelse
    endforeach
  endelse
  
  ; Compute Geomagnetic Axis
  if keyword_set(mag) then begin 
    
    ; First, we have to set the date for transformations
    if keyword_set(aacgm_date) then begin
      aacgm_yy = fix(strmid(aacgm_date,0,4))
      aacgm_mm = fix(strmid(aacgm_date,5,2))
      aacgm_dd = fix(strmid(aacgm_date,8,2))
      !null = aacgm_v2_setdatetime(aacgm_yy, aacgm_mm, aacgm_dd)
    endif else begin
      !null = aacgm_v2_setnow()
    endelse
    
    if where(float(altitude_km) eq interp_alts, /null) ne !null then begin
      ; no interpolation required
      alt_idx = where(float(altitude_km) eq interp_alts, /null)

      ; Grab all latitudes
      mag_y = []
      foreach row_idx, keogram_struct.ccd_y do begin
        if keogram_struct.axis eq 0 then begin
          lat = lats[slice_idx, row_idx, alt_idx]
          lon = lons[slice_idx, row_idx, alt_idx]
          mag_pos = cnvcoord_v2(lat, lon, aacgm_height, verbose=-1)
          lat = mag_pos[0]
          mag_y = [mag_y, lat]
        endif else begin
          lat = lats[row_idx, slice_idx, alt_idx]
          lon = lons[row_idx, slice_idx, alt_idx]
          mag_pos = cnvcoord_v2(lat, lon, aacgm_height, verbose=-1)
          lon = mag_pos[1]
          mag_y = [mag_y, lon]
        endelse
      endforeach
    endif else begin
      ; interpolation is required
      ; first check if supplied altitude is valid for interpolation
      if (altitude_km lt min(interp_alts)) or (altitude_km gt max(interp_alts)) then begin
        error_msg = '[aurorax_keogram_add_axis] Error: Altitude of ' + strcompress(string(altitude_km), /remove_all) + ' km is outside the valid ' + $
          'range of [' + strcompress(string(min(interp_alts)), /remove_all) + ',' + strcompress(string(max(interp_alts)), /remove_all) + '] km.'
        print, error_msg
        return, !null
      endif
      
      ; Interpolate all latitudes
      mag_y = []
      foreach row_idx, keogram_struct.ccd_y do begin
        if keogram_struct.axis eq 0 then begin
          lat = interpol(reform(lats[slice_idx, row_idx, *]), interp_alts, altitude_km)
          lon = interpol(reform(lons[slice_idx, row_idx, *]), interp_alts, altitude_km)
          mag_pos = cnvcoord_v2(lat, lon, aacgm_height, verbose=-1)
          lat = mag_pos[0]
          mag_y = [mag_y, lat]
        endif else begin
          lat = interpol(reform(lats[row_idx, slice_idx, *]), interp_alts, altitude_km)
          lon = interpol(reform(lons[row_idx, slice_idx, *]), interp_alts, altitude_km)
          mag_pos = cnvcoord_v2(lat, lon, aacgm_height, verbose=-1)
          lon = mag_pos[1]
          mag_y = [mag_y, lon]
        endelse
      endforeach
    endelse
  endif

  keywords = [keyword_set(geo), keyword_set(mag), keyword_set(elev)]

  if array_equal(keywords, [0, 0, 1]) then begin
    ; Elevation 
    return, {data: keo_arr, timestamp: time_stamp, ut_decimal: keogram_struct.ut_decimal, ccd_y: ccd_y, slice_idx: slice_idx, axis: keogram_struct.axis, elev_y: elev_y}
  endif else if array_equal(keywords, [0, 1, 0]) then begin
    ; Magnetic
    return, {data: keo_arr, timestamp: time_stamp, ut_decimal: keogram_struct.ut_decimal, ccd_y: ccd_y, slice_idx: slice_idx, axis: keogram_struct.axis, mag_y: mag_y}
  endif else if array_equal(keywords, [0, 1, 1]) then begin
    ; Magnetic and Elevation
    return, {data: keo_arr, timestamp: time_stamp, ut_decimal: keogram_struct.ut_decimal, ccd_y: ccd_y, slice_idx: slice_idx, axis: keogram_struct.axis, elev_y: elev_y, mag_y: mag_y}
  endif else if array_equal(keywords, [1, 0, 0]) then begin
    ; Geographic
    return, {data: keo_arr, timestamp: time_stamp, ut_decimal: keogram_struct.ut_decimal, ccd_y: ccd_y, slice_idx: slice_idx, axis: keogram_struct.axis, geo_y: geo_y}
  endif else if array_equal(keywords, [1, 0, 1]) then begin
    ; Geographic and Elevation
    return, {data: keo_arr, timestamp: time_stamp, ut_decimal: keogram_struct.ut_decimal, ccd_y: ccd_y, slice_idx: slice_idx, axis: keogram_struct.axis, geo_y: geo_y, elev_y: elev_y}
  endif else if array_equal(keywords, [1, 1, 0]) then begin
    ; Geographic and Magnetic
    return, {data: keo_arr, timestamp: time_stamp, ut_decimal: keogram_struct.ut_decimal, ccd_y: ccd_y, slice_idx: slice_idx, axis: keogram_struct.axis, geo_y: geo_y, mag_y: mag_y}
  endif else if array_equal(keywords, [1, 1, 1]) then begin
    ; Geographic and Magnetic and Elevation
    return, {data: keo_arr, timestamp: time_stamp, ut_decimal: keogram_struct.ut_decimal, ccd_y: ccd_y, slice_idx: slice_idx, axis: keogram_struct.axis, geo_y: geo_y, elev_y: elev_y, mag_y: mag_y}
  endif
end
