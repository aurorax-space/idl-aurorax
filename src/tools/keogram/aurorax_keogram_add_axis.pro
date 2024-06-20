
function aurorax_keogram_add_axis, keogram_struct, skymap, altitude_km=altitude_km, geo=geo, mag=mag, elev=elev
    
    if keyword_set(geo) and not keyword_set(altitude_km) then begin
        stop, "(aurorax_keogram_add_axis) Error: Using '/geo' or '/mag' requires passing in 'altitude_km'."
    endif
    
    ; Determine number of channels and height of keogram
    time_stamp = keogram_struct.timestamp
    keo_arr = keogram_struct.data
    if n_elements(size(keo_arr, /dimensions)) eq 3 then begin
        n_channels = (size(keo_arr, /dimensions))[0]
        keo_height = (size(keo_arr, /dimensions))[2]
    endif else if n_elements(size(keo_arr, /dimensions)) eq 1 then begin
        n_channels = 1
        keo_height = (size(keo_arr, /dimensions))[1]
    endif
    
    ; Check that at least one keyword is passed
    if not keyword_set(geo) and not keyword_set(mag) and not keyword_set(geo) then begin
        stop, "(aurorax_keogram_add_axis) Error: At least one of '/geo', '/mag', '/elev', must be set to add axes.'
    endif
    ; Check that skymap size matches keogram
    if (size(skymap.full_azimuth, /dimensions))[1] ne keo_height then begin
        stop, "(aurorax_keogram_add_axis) Error: Skymap size does not match size of 
    endif
    
    ; Obtain keogram index in CCD coords
    slice_idx = keogram_struct.slice_idx
    
    ; grab necessary data from skymap
    altitudes = skymap.full_map_altitude
    lats = skymap.full_map_latitude
    lons = skymap.full_map_longitude
    lons[where(lons gt 180)] -= 360
    elevation = skymap.full_elevation
    
    ; grab ccd axis
    ccd_y = keogram_struct.ccd_y
    
    ; Create elevation axis
    elev_y = []
    foreach row_idx, keogram_struct.ccd_y do begin
        el = elevation[slice_idx, row_idx]
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
            lat = lats[slice_idx, row_idx, alt_idx]
            geo_y = [geo_y, lat]
        endforeach
    endif else begin
        ; interpolation is required
        ; first check if supplied altitude is valid for interpolation
        if (alitude_km lt min(interp_alts)) or (alitude_km gt max(interp_alts)) then begin
            error_msg = "(aurorax_keogram_add_axis) Error: Altitude of "+strcompress(string(altitude_km),/remove_all)+" km is outside the valid " + $
                        "range of ["+strcompress(string(min(interp_alts)),/remove_all)+","+strcompress(string(max(interp_alts)),/remove_all)+"] km."
            stop, error_msg
        endif
        
        ; Interpolate all latitudes
        geo_y = []
        foreach row_idx, keogram_struct.ccd_y do begin
            lat = interpol(lats[slice_idx, row_idx, *], interp_alts, altitude_km)
            geo_y = [geo_y, lat]
        endforeach
    endelse
    
    if keyword_set(mag) then begin
        ; Magnetic conversion goes here
        mag_y = geo_y ; TEMP ***************** JOSH FIX THIS
    endif
    
    keywords = [keyword_set(geo), keyword_set(mag), keyword_set(elev)]
    
;    ; Reverse all axes
;    if keyword_set(geo) then geo_y = reverse(geo_y)
;    if keyword_set(mag) then mag_y = reverse(mag_y)
;    if keyword_set(elev) then elev_y = reverse(elev_y)
    
    if array_equal(keywords, [0,0,1]) then begin
        ; Return keogram array with desired axes added
        return, {data:keo_arr, timestamp:time_stamp, ccd_y:ccd_y, slice_idx:slice_idx, elev_y:elev_y}
    endif else if array_equal(keywords, [0,1,0]) then begin
        ; Return keogram array with desired axes added
        return, {data:keo_arr, timestamp:time_stamp, ccd_y:ccd_y, slice_idx:slice_idx, mag_y:mag_y}
    endif else if array_equal(keywords, [0,1,1]) then begin
        ; Return keogram array with desired axes added
        return, {data:keo_arr, timestamp:time_stamp, ccd_y:ccd_y, slice_idx:slice_idx, mag_y:mag_y, elev_y:elev_y}
    endif else if array_equal(keywords, [1,0,0]) then begin
        ; Return keogram array with desired axes added
        return, {data:keo_arr, timestamp:time_stamp, ccd_y:ccd_y, slice_idx:slice_idx, geo_y:geo_y}
    endif else if array_equal(keywords, [1,0,1]) then begin
        ; Return keogram array with desired axes added
        return, {data:keo_arr, timestamp:time_stamp, ccd_y:ccd_y, slice_idx:slice_idx, geo_y:geo_y, elev_y:elev_y}
    endif else if array_equal(keywords, [1,1,0]) then begin
        ; Return keogram array with desired axes added
        return, {data:keo_arr, timestamp:time_stamp, ccd_y:ccd_y, slice_idx:slice_idx, geo_y:geo_y, mag_y:mag_y}
    endif else if array_equal(keywords, [1,1,1]) then begin
        ; Return keogram array with desired axes added
        return, {data:keo_arr, timestamp:time_stamp, ccd_y:ccd_y, slice_idx:slice_idx, geo_y:geo_y, mag_y:mag_y, elev_y:elev_y}
    endif 
    
end