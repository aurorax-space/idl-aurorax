

function aurorax_bounding_box_extract_metric, images, mode, xy_bounds, metric=metric, show_preview=show_preview, time_stamp=timestamp, skymap=skymap, altitude_km=altitude_km, n_channels=n_channels, azim=azim, ccd=ccd, elev=elev, geo=geo, mag=mag
    
    metrics = ["mean", "median", "sum"]
    if not keyword_set(metric) then metric = "median"
    if where(metric eq metrics, /null) eq !null then begin
        stop, "(aurorax_bounding_box_extract_metric) Error: Metric '"+string(metric)+"' not recognized. Accepted metrics are: "+strjoin(modes, ",")+"."
    endif
    
    modes = ["azim", "ccd", "elev", "geo", "mag"]
    mode_idx = where(strlowcase(mode) eq modes, /null)
    if mode_idx eq !null then begin
        stop, "(aurorax_bounding_box_extract_metric) Error: Mode '"+string(mode)+"' not recognized. Accepted modes are: "+strjoin(modes, ",")+"."
    endif
    mode = strlowcase(mode)
    
    ; Get number of channels
    if n_elements(size(images, /dimensions)) eq 4 then begin
        n_channels = (size(images,/dimensions))[0]
    endif else begin
        images = reform(images)
        if (size(images,/dimensions))[0] eq 3 then begin
            n_channels = 3
        endif else begin
            n_channels = 1
        endelse
    endelse
    
    ; Reform to prevent indexing errors later
    if (n_channels eq 3) and n_elements(size(images, /dimensions)) eq 3 then begin
        images = reform(images, (size(images, /dimensions))[0], (size(images, /dimensions))[1], (size(images, /dimensions))[2], 1)
    endif else if (n_channels eq 1) and n_elements(size(images, /dimensions)) eq 2 then begin
        images = reform(images, (size(images, /dimensions))[0], (size(images, /dimensions))[2], 1)
    endif
    
    if mode eq "azim" then begin
        if (not isa(xy_bounds, /array)) or (n_elements(xy_bounds) ne n_elements([0,0])) then begin
            stop, "(aurorax_bounding_box_extract_metric) Error: xy_array must be a two-element array specifying [min_azim, max_azim]."
        endif
        
        ; Select individual azimuths from array
        az_0 = xy_bounds[0]
        az_1 = xy_bounds[1]
        
        ; Ensure that coordinates are valid
        if az_0 gt 360 or az_0 lt 0 then begin
            stop, "Invalid Azimuth: " + strcompress(string(az_0), /remove_all)
        endif else if az_1 gt 360 or az_1 lt 0 then begin
            stop, "Invalid Azimuth: " + strcompress(string(az_1), /remove_all)
        endif
        
        ; Ensure that azimuths are properly ordered
        if az_0 gt az_1 then begin
            tmp = az_0
            az_0 = az_1
            az_1 = tmp
        endif
        
        ; Ensure that this is a valid area
        if az_0 eq az_1 then stop, "(aurorax_bounding_box_extract_metric) Error: Azimuth range defined with zero area, ensure that min_azim and max_azim are different."
        
        ; Obtain azimuth array from skymap
        if not keyword_set(skymap) then stop, "(aurorax_bounding_box_extract_metric) Error: Skymap is required for range defined in azimuth space."
        az = skymap.full_azimuth
        
        ; Get index into flattened CCD corresponding to bounded area
        flattened_az = reform(az, (size(az, /dimensions))[0]*(size(az, /dimensions))[1])
        bounded_idx = where((flattened_az gt float(az_0)) and (flattened_az lt float(az_1) and finite(az)), /null)

        ; If boundaries contain no data, raise error
        if bounded_idx eq !null then stop, "(aurorax_bounding_box_extract_metric) Error: Could not extract data within azimuth bounds. Try a larger area."
                
        ; Slice data of interest from images
        if n_channels eq 1 then begin
            ; flatten images for indexing 
            flat_images = reform(images, (size(images, /dimensions))[0]*(size(images, /dimensions))[1], (size(images, /dimensions))[2])
            if keyword_set(show_preview) then begin
                ; plot the first image, with bounded idx masked
                preview_img = bytscl(flat_images[*,0], top=230)
                preview_img[bounded_idx] = 255
                preview_img = reform(preview_img, (size(images, /dimensions))[0], (size(images, /dimensions))[1])
                im = image(preview_img, rgb_table=0, title="Preview of Bounded Area")
            endif
            
            ; Obtain bounded data and then take metric over all images
            flat_bounded_data = flat_images[bounded_idx,*]
            if metric eq "median" then begin
                result = reform(median(flat_bounded_data, dimension=1))
            endif else if metric eq "mean" then begin
                result = reform(mean(flat_bounded_data, dimension=1))
            endif else if metric eq "sum" then begin
                result = reform(total(flat_bounded_data, dimension=1))
            endif
        endif else if n_channels eq 3 then begin
            ; flatten images
            flat_images = reform(images, 3, (size(images, /dimensions))[1]*(size(images, /dimensions))[2], (size(images, /dimensions))[3])
            if keyword_set(show_preview) then begin
                ; plot the first image, with bounded idx masked
                preview_img = bytscl(flat_images[*,*,0], top=230)
                preview_img[0,bounded_idx] = 255
                preview_img[1:*,bounded_idx] = 0
                preview_img = reform(preview_img, 3, (size(images, /dimensions))[1], (size(images, /dimensions))[2])
                im = image(preview_img, title="Preview of Bounded Area")
            endif
            
            ; Obtain bounded data and then take metric over all images
            flat_bounded_data = flat_images[*,bounded_idx,*]
            if metric eq "median" then begin
                result = reform(median(flat_bounded_data, dimension=2))
            endif else if metric eq "mean" then begin
                result = reform(mean(flat_bounded_data, dimension=2))
            endif else if metric eq "sum" then begin
                result = reform(total(flat_bounded_data, 2))
            endif
        endif else begin
            stop, "Unrecognized image format with "+strcompress(string(n_elements(size(images,/dimensions))),/remove_all)+" dimensions."
        endelse
        
        return, result
        
    endif else if mode eq "ccd" then begin
        if (not isa(xy_bounds, /array)) or (n_elements(xy_bounds) ne n_elements([0,0,0,0])) then begin
            stop, "(aurorax_bounding_box_extract_metric) Error: xy_array must be a four-element array specifying [ccd_x0, ccd_x1, ccd_y0, ccd_y1]."
        endif

        ; Select individual azimuths from array
        x_0 = xy_bounds[0]
        x_1 = xy_bounds[1]
        y_0 = xy_bounds[2]
        y_1 = xy_bounds[3]
        
        ; determine max ccd_x and ccd_y
        if n_channels eq 1 then begin
            max_x = (size(images, /dimensions))[0]
            max_y = (size(images, /dimensions))[1]
        endif else if n_channels eq 3 then begin
            max_x = (size(images, /dimensions))[1]
            max_y = (size(images, /dimensions))[2]
        endif else begin
            stop, "Unrecognized image format with "+strcompress(string(n_elements(size(images,/dimensions))),/remove_all)+" dimensions."
        endelse
        
        ; Ensure that coordinates are valid
        if y_0 gt max_y or y_0 lt 0 then begin
            stop, "CCD Y Coordinate " + strcompress(string(y_0),/remove_all) + " out of range for image of shape (" + strcompress(string(max_y),/remove_all) +$
                  ","+strcompress(string(max_x)) + ")."
        endif else if y_1 gt max_y or y_1 lt 0 then begin
            stop, "CCD Y Coordinate " + strcompress(string(y_1),/remove_all) + " out of range for image of shape (" + strcompress(string(max_y),/remove_all) +$
                  ","+strcompress(string(max_x)) + ")."
        endif else if x_0 gt max_x or x_0 lt 0 then begin
            stop, "CCD Y Coordinate " + strcompress(string(x_0),/remove_all) + " out of range for image of shape (" + strcompress(string(max_y),/remove_all) +$
                  ","+strcompress(string(max_x)) + ")."
        endif else if x_1 gt max_x or x_1 lt 0 then begin
            stop, "CCD Y Coordinate " + strcompress(string(x_1),/remove_all) + " out of range for image of shape (" + strcompress(string(max_y),/remove_all) +$
                  ","+strcompress(string(max_x)) + ")."
        endif
        
        ; Ensure that coordinates are properly ordered
        if y_0 gt y_1 then begin
            tmp = y_0
            y_0 = y_1
            y_1 = tmp
        endif else if x_0 gt x_1 then begin
            tmp = x_0
            x_0 = x_1
            x_1 = tmp
        endif

        ; Ensure that this is a valid area
        if x_1 eq x_0 or y_1 eq y_0 then stop, "(aurorax_bounding_box_extract_metric) Error: Azimuth range defined with zero area, ensure that min_azim and max_azim are different."

        ; Obtain azimuth array from skymap
        if not keyword_set(skymap) then stop, "(aurorax_bounding_box_extract_metric) Error: Skymap is required for range defined in azimuth space."
        az = skymap.full_azimuth

        ; Slice data of interest from images
        if n_channels eq 1 then begin
            if keyword_set(show_preview) then begin
                ; plot the first image, with bounded idx masked
                preview_img = bytscl(images[*,*,0], top=230)
                preview_img[x_0:x_1,y_0:y_1] = 255
                im = image(preview_img, rgb_table=0, title="Preview of Bounded Area")
            endif

            ; Obtain bounded data and then take metric over all images
            bounded_data = images[x_0:x_1,y_0:y_1,*]
            if metric eq "median" then begin
                result = reform(median(median(bounded_data, dimension=1), dimension=1))
            endif else if metric eq "mean" then begin
                result = reform(mean(mean(bounded_data, dimension=1), dimension=1))
            endif else if metric eq "sum" then begin
                result = reform(total(total(bounded_data, 1), 1))
            endif
        endif else if n_channels eq 3 then begin
            if keyword_set(show_preview) then begin
                ; plot the first image, with bounded idx masked
                preview_img = bytscl(images[*,*,*,0], top=230)
                preview_img[0,x_0:x_1,y_0:y_1] = 255
                preview_img[1:*,x_0:x_1,y_0:y_1] = 0
                im = image(preview_img, title="Preview of Bounded Area")
            endif

            ; Obtain bounded data and then take metric over all images
            bounded_data = images[*,x_0:x_1,y_0:y_1,*]
            if metric eq "median" then begin
                result = reform(median(median(bounded_data, dimension=2), dimension=2))
            endif else if metric eq "mean" then begin
                result = reform(mean(mean(bounded_data, dimension=2), dimension=2))
            endif else if metric eq "sum" then begin
                result = reform(total(total(bounded_data, 2), 2))
            endif
        endif else begin
            stop, "Unrecognized image format with "+strcompress(string(n_elements(size(images,/dimensions))),/remove_all)+" dimensions."
        endelse

        return, result
        
    endif else if mode eq "elev" then begin
        if (not isa(xy_bounds, /array)) or (n_elements(xy_bounds) ne n_elements([0,0])) then begin
            stop, "(aurorax_bounding_box_extract_metric) Error: xy_array must be a two-element array specifying [min_el, max_el]."
        endif

        ; Select individual elevations from array
        el_0 = xy_bounds[0]
        el_1 = xy_bounds[1]

        ; Ensure that coordinates are valid
        if el_0 gt 90 or el_0 lt 0 then begin
            stop, "Invalid Elevation: " + strcompress(string(el_0), /remove_all)
        endif else if el_1 gt 90 or el_1 lt 0 then begin
            stop, "Invalid Elevation: " + strcompress(string(el_1), /remove_all)
        endif

        ; Ensure that elevations are properly ordered
        if el_0 gt el_1 then begin
            tmp = el_0
            el_0 = el_1
            el_1 = tmp
        endif

        ; Ensure that this is a valid area
        if el_0 eq el_1 then stop, "(aurorax_bounding_box_extract_metric) Error: Elevation range defined with zero area, ensure that min_el and max_el are different."

        ; Obtain elevation array from skymap
        if not keyword_set(skymap) then stop, "(aurorax_bounding_box_extract_metric) Error: Skymap is required for range defined in elevation space."
        el = skymap.full_elevation

        ; Get index into flattened CCD corresponding to bounded area
        flattened_el = reform(el, (size(el, /dimensions))[0]*(size(el, /dimensions))[1])
        bounded_idx = where((flattened_el gt float(el_0)) and (flattened_el lt float(el_1) and finite(el)), /null)

        ; If boundaries contain no data, raise error
        if bounded_idx eq !null then stop, "(aurorax_bounding_box_extract_metric) Error: Could not extract data within elevation bounds. Try a larger area."

        ; Slice data of interest from images
        if n_channels eq 1 then begin
            ; flatten images for indexing
            flat_images = reform(images, (size(images, /dimensions))[0]*(size(images, /dimensions))[1], (size(images, /dimensions))[2])
            if keyword_set(show_preview) then begin
                ; plot the first image, with bounded idx masked
                preview_img = bytscl(flat_images[*,0], top=230)
                preview_img[bounded_idx] = 255
                preview_img = reform(preview_img, (size(images, /dimensions))[0], (size(images, /dimensions))[1])
                im = image(preview_img, rgb_table=0, title="Preview of Bounded Area")
            endif

            ; Obtain bounded data and then take metric over all images
            flat_bounded_data = flat_images[bounded_idx,*]
            if metric eq "median" then begin
                result = reform(median(flat_bounded_data, dimension=1))
            endif else if metric eq "mean" then begin
                result = reform(mean(flat_bounded_data, dimension=1))
            endif else if metric eq "sum" then begin
                result = reform(total(flat_bounded_data, dimension=1))
            endif
        endif else if n_channels eq 3 then begin
            ; flatten images
            flat_images = reform(images, 3, (size(images, /dimensions))[1]*(size(images, /dimensions))[2], (size(images, /dimensions))[3])
            if keyword_set(show_preview) then begin
                ; plot the first image, with bounded idx masked
                preview_img = bytscl(flat_images[*,*,0], top=230)
                preview_img[0,bounded_idx] = 255
                preview_img[1:*,bounded_idx] = 0
                preview_img = reform(preview_img, 3, (size(images, /dimensions))[1], (size(images, /dimensions))[2])
                im = image(preview_img, title="Preview of Bounded Area")
            endif

            ; Obtain bounded data and then take metric over all images
            flat_bounded_data = flat_images[*,bounded_idx,*]
            if metric eq "median" then begin
                result = reform(median(flat_bounded_data, dimension=2))
            endif else if metric eq "mean" then begin
                result = reform(mean(flat_bounded_data, dimension=2))
            endif else if metric eq "sum" then begin
                result = reform(total(flat_bounded_data, 2))
            endif
        endif else begin
            stop, "Unrecognized image format with "+strcompress(string(n_elements(size(images,/dimensions))),/remove_all)+" dimensions."
        endelse

        return, result
        
    endif else if mode eq "geo" then begin
        if (not isa(xy_bounds, /array)) or (n_elements(xy_bounds) ne n_elements([0,0,0,0])) then begin
            stop, "(aurorax_bounding_box_extract_metric) Error: xy_array must be a four-element array specifying [lon_0, lon_1, lat_0, lat_1]."
        endif

        ; Select individual lat/lon from array
        lon_0 = xy_bounds[0]
        lon_1 = xy_bounds[1]
        lat_0 = xy_bounds[2]
        lat_1 = xy_bounds[3]

        ; Ensure that coordinates are valid
        if lat_0 gt 90. or lat_0 lt -90. then begin
            stop, "Latitude " + strcompress(string(lat_0),/remove_all) + " out of range (-90,90)."
        endif else if lat_1 gt 90. or lat_1 lt -90. then begin
            stop, "Latitude " + strcompress(string(lat_1),/remove_all) + " out of range (-90,90)."
        endif else if lon_0 gt 180. or lon_0 lt -180. then begin
            stop, "Longitude " + strcompress(string(lon_0),/remove_all) + " out of range (-180,180)."
        endif else if lon_1 gt 180. or lon_1 lt -180. then begin
            stop, "Longitude " + strcompress(string(lon_0),/remove_all) + " out of range (-180,180)."
        endif

        ; Ensure that coordinates are properly ordered
        if lat_0 gt lat_1 then begin
            tmp = lat_0
            lat_0 = lat_1
            lat_1 = tmp
        endif else if lon_0 gt lon_1 then begin
            tmp = lon_0
            lon_0 = lon_1
            lon_1 = tmp
        endif

        ; Ensure that this is a valid area
        if lat_1 eq lat_0 or lon_1 eq lon_0 then stop, "(aurorax_bounding_box_extract_metric) Error: Coordinate range defined with zero area, ensure that lats and lons are different."
        
        ; grab necessary data from skymap
        altitudes = skymap.full_map_altitude
        lats = skymap.full_map_latitude
        lons = skymap.full_map_longitude
        lons[where(lons gt 180)] -= 360
        elev = skymap.full_elevation


        ; convert altitudes to km for interpolation
        interp_alts = altitudes / 1000.
        if not isa(altitude_km) then stop, "Altitude must be provided when working in lat/lon coordinates."
        

        if where(float(altitude_km) eq interp_alts, /null) ne !null then begin
            ; no interpolation required
            alt_idx = where(float(altitude_km) eq interp_alts, /null)
            
            ; grab lat/lons at this altitude
            lats = lats[*,*,alt_idx]
            lons = lons[*,*,alt_idx]

        endif else begin
            ; interpolation is required
            lats_xsize = (size(lats, /dimensions))[0]
            lats_ysize = (size(lats, /dimensions))[1]
            ; first check if supplied altitude is valid for interpolation
            if (altitude_km lt min(interp_alts)) or (altitude_km gt max(interp_alts)) then begin
                error_msg = "(aurorax_mosaic_prep_skymap) Error: Altitude of "+strcompress(string(altitude_km),/remove_all)+" km is outside the valid " + $
                            "range of ["+strcompress(string(min(interp_alts)),/remove_all)+","+strcompress(string(max(interp_alts)),/remove_all)+"] km."
                stop, error_msg
            endif
            ; interpolate entire lat lon arrays
            new_lats = lats[*,*,0]
            new_lons = lons[*,*,0]
            for i=0, lats_xsize-1 do begin
                for j=0, lats_ysize-1 do begin
                    new_lats[i,j] = interpol(lats[i,j,*], interp_alts, altitude_km)
                    new_lons[i,j] = interpol(lons[i,j,*], interp_alts, altitude_km)
                endfor
            endfor
            lats = new_lats
            lons = new_lons
        endelse
        
        ;Check that lat/lon range is reasonable
        min_skymap_lat = min(lats, /nan)
        max_skymap_lat = max(lats, /nan)
        min_skymap_lon = min(lons, /nan)
        max_skymap_lon = max(lons, /nan)
        if (lat_0 le min_skymap_lat) or (lat_1 ge max_skymap_lat) then begin
            stop, "Latitude range supplied is outside the valid range for this skymap ("+strcompress(string(min_skymap_lat),/remove_all)+$
                  ","+strcompress(string(max_skymap_lat),/remove_all)+")."
        endif
        if (lon_0 le min_skymap_lon) or (lon_1 ge max_skymap_lon) then begin
            stop, "Longitude range supplied is outside the valid range for this skymap ("+strcompress(string(min_skymap_lon),/remove_all)+$
                  ","+strcompress(string(max_skymap_lon),/remove_all)+")." 
        endif
        
        ; Get index into flattened CCD corresponding to bounded area
        flattened_lats = reform(lats[1:*,1:*], ((size(lats, /dimensions))[0]-1)*((size(lats, /dimensions))[1]-1))
        flattened_lons = reform(lons[1:*,1:*], ((size(lons, /dimensions))[0]-1)*((size(lons, /dimensions))[1]-1))
        bounded_idx = where((flattened_lats ge float(lat_0)) and (flattened_lats le float(lat_1)) and (flattened_lons ge float(lon_0)) and (flattened_lons le float(lon_1)), /null)
        
        ; If boundaries contain no data, raise error
        if bounded_idx eq !null then stop, "(aurorax_bounding_box_extract_metric) Error: Could not extract data within lat/lon bounds. Try a larger area."

        ; Slice data of interest from images
        if n_channels eq 1 then begin
            ; flatten images for indexing
            flat_images = reform(images, (size(images, /dimensions))[0]*(size(images, /dimensions))[1], (size(images, /dimensions))[2])
            if keyword_set(show_preview) then begin
                ; plot the first image, with bounded idx masked
                preview_img = bytscl(flat_images[*,0], top=230)
                preview_img[bounded_idx] = 255
                preview_img = reform(preview_img, (size(images, /dimensions))[0], (size(images, /dimensions))[1])
                im = image(preview_img, rgb_table=0, title="Preview of Bounded Area")
            endif

            ; Obtain bounded data and then take metric over all images
            flat_bounded_data = flat_images[bounded_idx,*]
            if metric eq "median" then begin
                result = reform(median(flat_bounded_data, dimension=1))
            endif else if metric eq "mean" then begin
                result = reform(mean(flat_bounded_data, dimension=1))
            endif else if metric eq "sum" then begin
                result = reform(total(flat_bounded_data, dimension=1))
            endif
        endif else if n_channels eq 3 then begin
            ; flatten images
            flat_images = reform(images, 3, (size(images, /dimensions))[1]*(size(images, /dimensions))[2], (size(images, /dimensions))[3])
            if keyword_set(show_preview) then begin
                ; plot the first image, with bounded idx masked
                preview_img = bytscl(flat_images[*,*,0], top=230)
                preview_img[0,bounded_idx] = 255
                preview_img[1:*,bounded_idx] = 0
                preview_img = reform(preview_img, 3, (size(images, /dimensions))[1], (size(images, /dimensions))[2])
                im = image(preview_img, title="Preview of Bounded Area")
            endif

            ; Obtain bounded data and then take metric over all images
            flat_bounded_data = flat_images[*,bounded_idx,*]
            if metric eq "median" then begin
                result = reform(median(flat_bounded_data, dimension=2))
            endif else if metric eq "mean" then begin
                result = reform(mean(flat_bounded_data, dimension=2))
            endif else if metric eq "sum" then begin
                result = reform(total(flat_bounded_data, 2))
            endif
        endif else begin
            stop, "Unrecognized image format with "+strcompress(string(n_elements(size(images,/dimensions))),/remove_all)+" dimensions."
        endelse

        return, result
        
    endif else if mode eq "mag" then begin
        stop, "Magnetic coordinates are not yet supported for this routine..."
    endif
    
    
end