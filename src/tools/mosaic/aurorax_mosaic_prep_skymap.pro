
function aurorax_mosaic_prep_skymap, skymap_list, altitude_km

    if typename(skymap_list) ne 'LIST' then stop, "(aurorax_mosaic_prep_skymap) Error: Input skymaps must be stored in a list. Recieved type: "+typename(skymap_list)
    if not isa(altitude_km, /scalar) then stop, "(aurorax_mosaic_prep_skymap) Error: Altitude must be a scalar. Recieved type: "+typename(altitude_km)
    
    elevation = list()
    polyfill_lat = list()
    polyfill_lon = list()
    site_uid = []
    for k=0, n_elements(skymap_list)-1 do begin
        
        skymap = skymap_list[k]
        site_uid = [site_uid, skymap.site_uid]
        
        ; set image dimensions
        width = (size(skymap.full_azimuth, /dimensions))[0]
        height = (size(skymap.full_azimuth, /dimensions))[1]

        ; grab necessary data from skymap
        altitudes = skymap.full_map_altitude
        lats = skymap.full_map_latitude
        lons = skymap.full_map_longitude
        lons[where(lons gt 180)] -= 360
        elev = skymap.full_elevation

        ; create this site's filling arrays
        site_polyfill_lon = dblarr(5, width, height)
        site_polyfill_lat = dblarr(5, width, height)

        ; convert altitudes to km for interpolation
        interp_alts = altitudes / 1000.

        ; iterate through each image pixel
        for i=0, width-1 do begin
            for j=0, height-1 do begin

                if ~ finite(elev[i,j]) then continue

                if where(float(altitude_km) eq interp_alts, /null) ne !null then begin
                    ; no interpolation required
                    alt_idx = where(float(altitude_km) eq interp_alts, /null)
                    
                    ; grab longitudes of pixel corners at desired altitudes
                    lon1 = lons[i, j, alt_idx]
                    lon2 = lons[i+1, j, alt_idx]
                    lon3 = lons[i+1, j+1, alt_idx]
                    lon4 = lons[i, j+1, alt_idx]
                    pix_lons = [lon1, lon2, lon3, lon4, lon1]

                    ; Skip any nans, as we only fill pixels with 4 finite corners
                    if where(~finite(pix_lons), /null) ne !null then continue
                    
                    ; repeat above for latitudes
                    lat1 = lats[i, j, alt_idx]
                    lat2 = lats[i+1, j, alt_idx]
                    lat3 = lats[i+1, j+1, alt_idx]
                    lat4 = lats[i, j+1, alt_idx]
                    pix_lats = [lat1, lat2, lat3, lat4, lat1]
                    
                    ; Skip any nans, as we only fill pixels with 4 finite corners
                    if where(~finite(pix_lons), /null) ne !null then continue
                    
                    ; Insert into master arrays
                    site_polyfill_lon[*,i,j] = pix_lons
                    site_polyfill_lat[*,i,j] = pix_lats
                    
                endif else begin
                    ; interpolation is required
                    ; first check if supplied altitude is valid for interpolation
                    if (altitude_km lt min(interp_alts)) or (altitude_km gt max(interp_alts)) then begin
                        error_msg = "(aurorax_mosaic_prep_skymap) Error: Altitude of "+strcompress(string(altitude_km),/remove_all)+" km is outside the valid " + $
                                    "range of ["+strcompress(string(min(interp_alts)),/remove_all)+","+strcompress(string(max(interp_alts)),/remove_all)+"] km."
                        stop, error_msg
                    endif
                    
                    ; interpolate longitudes of pixel corners at desired altitudes
                    lon1 = interpol(lons[i, j, *], interp_alts, altitude_km)
                    lon2 = interpol(lons[i+1, j, *], interp_alts, altitude_km)
                    lon3 = interpol(lons[i+1, j+1, *], interp_alts, altitude_km)
                    lon4 = interpol(lons[i, j+1, *], interp_alts, altitude_km)
                    help, lons[i, j+1, *]
                    help, interp_alts
                    pix_lons = [lon1, lon2, lon3, lon4, lon1]

                    ; Skip any nans, as we only fill pixels with 4 finite corners
                    if where(~finite(pix_lons), /null) ne !null then continue
                    stop
                    ; repeat above for latitudes
                    lat1 = interpol(lats[i, j, *], interp_alts, altitude_km)
                    lat2 = interpol(lats[i+1, j, *], interp_alts, altitude_km)
                    lat3 = interpol(lats[i+1, j+1, *], interp_alts, altitude_km)
                    lat4 = interpol(lats[i, j+1, *], interp_alts, altitude_km)
                    pix_lats = [lat1, lat2, lat3, lat4, lat1]

                    ; Skip any nans, as we only fill pixels with 4 finite corners
                    if where(~finite(pix_lons), /null) ne !null then continue

                    ; Insert into master arrays
                    site_polyfill_lon[*,i,j] = pix_lons
                    site_polyfill_lat[*,i,j] = pix_lats
                endelse
            endfor
        endfor
        
        ; Flatten this site's filling and elevation arrays and insert them into master arrays
        site_polyfill_lon = reform(site_polyfill_lon, 5, width * height)
        site_polyfill_lat = reform(site_polyfill_lat, 5, width * height)
        elev = reform(elev, (width * height))
        
        ; Add to master lists
        polyfill_lon.add, site_polyfill_lon
        polyfill_lat.add, site_polyfill_lat
        elevation.add, elev
    endfor
    
    ; cast into skymap_data struct
    prepped_skymaps = hash('polyfill_lat',polyfill_lat, 'polyfill_lon',polyfill_lon, 'elevation',elevation, 'site_uid',site_uid)

    return, prepped_skymaps
end




