



function aurorax_keogram_create_custom, images, time_stamp, coordinate_system, x_locs, y_locs, width=width, show_preview=show_preview, skymap=skymap, altitude_km=altitude_km, metric=metric
    
    ; check that coord system is valid
    coord_options = ['ccd', 'geo', 'mag']
    if where(coordinate_system eq coord_options, /null) eq !null then begin
        stop, "(aurorax_keogram_create_custom) Error: Accepted coordinate systems are 'ccd', 'geo', or 'mag'."
    endif
    
    if not isa(images, /array) then stop, "(aurorax_keogram_create_custom) Error: 'images' must be an array"


    ; Get the number of channels of image data
    images_shape = size(images, /dimensions)
    if n_elements(images_shape) eq 2 then begin
        stop, "(aurorax_keogram_create_custom) Error: 'images' must contain multiple frames."
    endif else if n_elements(images_shape) eq 3 then begin
        if images_shape[0] eq 3 then stop, "(aurorax_keogram_create_custom) Error: 'images' must contain multiple frames."
        n_channels = 1
    endif else if n_elements(images_shape) eq 4 then begin
        n_channels = images_shape[0]
    endif else stop, "(aurorax_keogram_create_custom) Error: Unable to determine number of channels based on the supplied images. " + $
                     "Make sure you are supplying a [cols,rows,images] or [channels,cols,rows,images] sized array."
        
    ; Set default width
    if not isa(width) then width = 3
    
    ; Check that all necessary parameters are supplied
    if coordinate_system eq "geo" or coordinate_system eq "mag" then begin
        if not keyword_set(skymap) or not keyword_set(altitude_km) then begin
            stop, "When working in lat/lon coordinates, a skymap and altitude must be supplied."
        endif
    endif
    
    ; Extract preview image if desired
    if keyword_set(show_preview) then begin
        if n_channels eq 1 then preview_img = images[*,*,0] else preview_img = images[*,*,*,0]
    endif
    
    ; Convert lat/lons to CCD coordinates
    if coordinate_system eq "geo" then begin
        result = __convert_lonlat_to_ccd(x_locs, y_locs, skymap, altitude_km)
        x_locs = result[0] & y_locs = result[1]
    endif else if coordinate_system eq "mag" then begin
        print, "(aurorax_keogram_create_custom) Warning: Magnetic coordinates are not currently supported for this routine."
        return, !null
        result = __convert_lonlat_to_ccd(x_locs, y_locs, skymap, altitude_km, timestamp=timestamp, /mag)
        x_locs = result[0] & y_locs = result[1]
    endif
    
    ; At this point, we work exclusively in CCD coordinates, everything has been converted

    ; Get max image indices
    if n_channels eq 1 then begin
        x_max = (size(images, /dimensions))[0]
        y_max = (size(images, /dimensions))[1]
    endif else if n_channels eq 3 then begin
        x_max = (size(images, /dimensions))[1]
        y_max = (size(images, /dimensions))[2]
    endif
    
    ; Remove any points that are not within the image CCD bounds
    parsed_x_locs = []
    parsed_y_locs = []
    for i=0, n_elements(x_locs)-1 do begin
        x = x_locs[i]
        y = y_locs[i]
        
        ; omit points outside of image bounds
        if x lt 0 or x gt x_max then continue
        if y lt 0 or y gt y_max then continue
        
        parsed_x_locs = [parsed_x_locs, x]
        parsed_y_locs = [parsed_y_locs, y]
    endfor
    
    ; Print message that some points have been removed if so
    if n_elements(parsed_x_locs) lt n_elements(x_locs) then begin
        print, "(aurorax_keogram_create_custom) Warning: Some input coordinates fall outside of the valid range for input image/skymap, and have been automatically removed."
    endif
    
    x_locs = parsed_x_locs
    y_locs = parsed_y_locs
    
    ; Iterate through points in pairs of two
    for i=0, n_elements(x_locs)-2 do begin
        
        ; Points of concern for this iteration
        x_0 = x_locs[i]
        x_1 = x_locs[i+1]
        y_0 = y_locs[i]
        y_1 = y_locs[i+1]

        ; Compute the unit vector between the two points
        dx = x_1 - x_0
        dy = y_1 - y_0
        length = sqrt(dx^2 + dy^2)
        if length eq 0 then begin
            stop, "Successive points may not be the same. Detected zero length between points of index ["+$
                  strcompress(string(i),/remove_all)+"] and ["+strcompress(string(i+1),/remove_all)+"]."
        endif
        dx /= length
        dy /= length
        
        ; Compute orthogonal unit vector
        perp_dx = -dy
        perp_dy = dx

        ; Calculate (+/-) offsets for each perpendicular direction
        offset1_x = perp_dx * width / 2.
        offset1_y = perp_dy * width / 2.
        offset2_x = -perp_dx * width / 2.
        offset2_y = -perp_dy * width / 2.

        ; Calculate vertices in correct order for this polygon
        vertex1 = [fix(x_0 + offset1_x), fix(y_0 + offset1_y)]
        vertex2 = [fix(x_1 + offset1_x), fix(y_1 + offset1_y)]
        vertex3 = [fix(x_1 + offset2_x), fix(y_1 + offset2_y)]
        vertex4 = [fix(x_0 + offset2_x), fix(y_0 + offset2_y)]
        
        ; Append vertices in the correct order to form a closed polygon
        vertices = list(vertex1, vertex2, vertex3, vertex4)
        
        ; Obtain the indexes into the image of this polygon
        help, vertices
    endfor
     
end


function __point_is_in_polygon, point, vertices
    ; function that checks if point is within polygon
    
    x = point[0]
    y = point[1]
    
    x_vertices = []
    y_vertices = []
    for i=0, n_elements(vertices)-1 do begin
        x_vertices = [x_vertices, (vertices[i])[0]]
        y_vertices = [y_vertices, (vertices[i])[1]]
    endfor
    
    ; Close the polygon
    closed_x = [x_vertices, x_vertices[0]]
    closed_y = [y_vertices, y_vertices[0]]
    i = indgen(n_elements(vertices))
    ii = indgen(n_elements(vertices)) + 1
    
    ; orthogonal vectors
    x1 = closed_x[i] - x 
    y1 = closed_y[i] - y
    x2 = closed_x[ii] - x 
    y2 = closed_y[ii] - y
    
    ; dot product and cross product
    dot = x1*x2 + y1*y2
    cross = x1*y2 - y1*x2
    theta = atan(cross,dot)
    
    ; return 1 if inside or on boundary, return 0 otherwise
    if (abs(total(theta)) gt !pi) then return, 1 else return, 0
END
   
   
   
function __indices_in_polygon, vertices, image_shape
    ; Function to obtain all indices of an array/image, within the 
    ; polygon defined by input list of ordered vertices.
    
    x_idx_inside = []
    y_idx_inside = []
    
    ; Iterate through every point in image
;    for i=0, images_shape[0]-1 do begin
;        for j=0, images_shape[1]-1 do begin
;            point = [i,j]
;            
;            if __point_is_in_polygon(point, vertices) do begin
;                x_idx_inside = [x_idx_inside, i]
;                y_idx_inside = [y_idx_inside, j]
;            endif
;        endfor
;    endfor
end
    
function __convert_lonlat_to_ccd, lon_locs, lat_locs, skymap, altitude_km, time_stamp=time_stamp, mag=mag
    
    if keyword_set(mag) and not keyword_set(time_stamp) then begin
        stop, "(__convert_lonlat_to_ccd) Error: Magnetic coordinates require a timestamp."
    endif
    
    interp_alts = skymap.full_map_altitude / 1000.
    
    ; Obtain lat/lon arrays at desired altitude
    ;
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
            error_msg = "(__convert_lonlat_to_ccd) Error: Altitude of "+strcompress(string(altitude_km),/remove_all)+" km is outside the valid " + $
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
    
    min_skymap_lat = min(lats, /nan)
    max_skymap_lat = max(lats, /nan)
    min_skymap_lon = min(lons, /nan)
    max_skymap_lon = max(lons, /nan)
    
    x_locs = []
    y_locs = []
    for i=0, n_elements(lat_locs)-1 do begin

        target_lat = lat_locs[i]
        target_lon = lon_locs[i]
        
        ; Ignore points outside of the skymap
        if target_lat lt min_skymap_lat or target_lat gt max_skymap_lat then continue
        if target_lon lt min_skymap_lon or target_lon gt max_skymap_lon then continue
        
        ; Compute the haversine distance between all points in skymap
        haversine_diff = __haversine_distances(target_lat, target_lon, lats, lons)
        
        ; Compute the skymap indices of the nearest point
        flat_idx = (where(haversine_diff eq min(haversine_diff, /nan), /null))[0]
        reform_idx = array_indices(haversine_diff, flat_idx)
        
        ; Convert indices to CCD coordinates
        x_loc = reform_idx[0] - 1
        if x_loc lt 0 then x_loc = 0
        y_loc = reform_idx[1] - 1
        if y_loc lt 0 then y_loc = 0
        
        ; Add to arrays holding all CCD points
        x_locs = [x_locs, x_loc]
        y_locs = [y_locs, y_loc]
        
    endfor
    
    ; Return arrays of all CCD points. Note any points outside of skymap
    ; will have been automatically ommited
    return, list(x_locs, y_locs)
end


function __haversine_distances, target_lat, target_lon, lat_array, lon_array
    ; Computes the distance on the globe between target lat/lon,
    ; and all points defined by lat/lon arrays.
    
    ; earth radius (m)
    r = 6371000.0
    
    ; convert degrees to rads
    phi_1 = !dtor * target_lat
    phi_2 = !dtor * lat_array
    delta_phi = !dtor * (lat_array - target_lat)
    delta_lambda = !dtor * (lon_array - target_lon)
    
    ; Haversine formula
    a = (sin(delta_phi / 2.))^2 + cos(phi_1) * cos(phi_2) * (sin(delta_lambda / 2.))^2
    c = 2 * atan(sqrt(a), sqrt(1-a))
    
    return, r * c
    
end















