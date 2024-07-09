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

function __indices_in_polygon, vertices, image_shape
  ; Function to obtain all indices of an array/image, within the
  ; polygon defined by input list of ordered vertices.
  ;
  ; Note: This is a hidden function, and not available publicly
  x_verts = []
  y_verts = []
  for i=0, n_elements(vertices)-1 do begin
    x_verts = [x_verts, (vertices[i])[0]]
    y_verts = [y_verts, (vertices[i])[1]]
  endfor

  x_idx_inside = []
  y_idx_inside = []

  ; Iterate through every point in image
  i_idx = indgen(image_shape[0])
  i_indices = []
  for j=0, image_shape[1]-1 do begin
    i_indices = [i_indices, i_idx]
  endfor
  j_idx = indgen(image_shape[1])
  j_indices = []
  for j=0, image_shape[0]-1 do begin
    j_indices = [j_indices, j_idx]
  endfor

  obj = obj_new('IDLanROI', x_verts, y_verts)
  flat_idx = where(obj.containspoints(i_indices, j_indices))
  x_idx_inside = i_indices[flat_idx]
  y_idx_inside = j_indices[flat_idx]

  return, list(x_idx_inside, y_idx_inside)
end

function __haversine_distances, target_lat, target_lon, lat_array, lon_array
  ; Computes the distance on the globe between target lat/lon,
  ; and all points defined by lat/lon arrays.
  ;
  ; Note: This is a hidden function, and not available publicly

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

function __convert_lonlat_to_ccd, lon_locs, lat_locs, skymap, altitude_km, time_stamp=time_stamp, mag=mag
  ; Converts a set of lat lon points to CCD coordinates
  ; using a skymap.
  ;
  ; Note: This is a hidden function, and not available publicly

  if keyword_set(mag) and not keyword_set(time_stamp) then begin
    print, "[__convert_lonlat_to_ccd] Error: Magnetic coordinates require a timestamp."
    return, !null
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
  if not isa(altitude_km) then begin
    print, "[__convert_lonlat_to_ccd] Error: altitude must be provided when working in lat/lon coordinates."
    return, !null
  endif

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
      error_msg = "[__convert_lonlat_to_ccd] Error: Altitude of "+strcompress(string(altitude_km),/remove_all)+" km is outside the valid " + $
        "range of ["+strcompress(string(min(interp_alts)),/remove_all)+","+strcompress(string(max(interp_alts)),/remove_all)+"] km."
      print, error_msg
      return, !null
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
  ; will have been automatically ommited. Note we flip the y locations
  ; as IDL plots y-pixel coordinates reversed.
  return, list(x_locs, (size(lats,/dimensions))[1]-y_locs)
end

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_KEOGRAM_CREATE_CUSTOM
;
; PURPOSE:
;       Create a keogram from a custom slice of image data.
;
; EXPLANATION:
;       Create a keogram by slicing image data along a custom contour
;       defined by lats/lons or CCD coordintes.
;
; CALLING SEQUENCE:
;       aurorax_keogram_create_custom(images, time_stamp, "ccd", x_locs, y_locs)
;
; PARAMETERS:
;       images                array of images to extract metric from
;       time_stamp            array of timestamps corresponding to each image frame
;       coordinate_system     a string giving the coordinate system ("ccd", "geo", "mag")
;       x_locs                the x locations, in desired coordinate system, to slice keogram along
;       y_locs                the y locations, in desired coordinate system, to slice keogram along
;       width                 the width of the keogram slice, in pixel units, optional (defaults to 2)
;       skymap                the skymap to use for georeferencing, optional
;       altitude_km           the altitude of the image data for georeferencing, optional
;       metric                the metric to use to compute each keogram pixel "median" (default), "mean", or "sum", optional
;
; KEYWORDS:
;       /SHOW_PREVIEW         plot a preview of the keogram slice on top of the first image frame
;
; OUTPUT
;       custom keogram structure containing keogram data and temporal axis
;
; OUTPUT TYPE:
;       struct
;
; EXAMPLES:
;       ccd_keo = aurorax_keogram_create_custom(img, time_stamp, "ccd", x_arr, y_arr, width=5, metric="sum", /show_preview)
;       geo_keo = aurorax_keogram_create_custom(img, time_stamp, "geo", longitudes, latitudes, skymap=skymap, altitude_km=113)
;+
;-------------------------------------------------------------
function aurorax_keogram_create_custom, images, time_stamp, coordinate_system, x_locs, y_locs, width=width, show_preview=show_preview, skymap=skymap, altitude_km=altitude_km, metric=metric

  ; check that coord system is valid
  coord_options = ['ccd', 'geo', 'mag']
  if where(coordinate_system eq coord_options, /null) eq !null then begin
    print, "[aurorax_keogram_create_custom] Error: accepted coordinate systems are 'ccd', 'geo', or 'mag'."
    return, !null
  endif

  if not isa(images, /array) then begin
    print, "[aurorax_keogram_create_custom] Error: 'images' must be an array"
    return, !null
  endif

  ; Get the number of channels of image data
  images_shape = size(images, /dimensions)
  if n_elements(images_shape) eq 2 then begin
    print, "[aurorax_keogram_create_custom] Error: 'images' must contain multiple frames."
    return, !null
  endif else if n_elements(images_shape) eq 3 then begin
    if images_shape[0] eq 3 then begin
      print, "[aurorax_keogram_create_custom] Error: 'images' must contain multiple frames."
      return, !null
    endif
    n_channels = 1
  endif else if n_elements(images_shape) eq 4 then begin
    n_channels = images_shape[0]
  endif else begin
    print, "[aurorax_keogram_create_custom] Error: Unable to determine number of channels based on the supplied images. " + $
      "Make sure you are supplying a [cols,rows,images] or [channels,cols,rows,images] sized array."
    return, !null
  endelse

  ; Set default width
  if not isa(width) then width = 2

  ; Check that all necessary parameters are supplied
  if coordinate_system eq "geo" or coordinate_system eq "mag" then begin
    if not keyword_set(skymap) or not keyword_set(altitude_km) then begin
      print, "When working in lat/lon coordinates, a skymap and altitude must be supplied."
      return, !null
    endif
  endif

  ; Extract preview image if desired
  if keyword_set(show_preview) then begin
    if n_channels eq 1 then preview_img = bytscl(images[*,*,0], top=230) else preview_img = images[*,*,*,0]
  endif

  ; Convert lat/lons to CCD coordinates
  if coordinate_system eq "geo" then begin
    result = __convert_lonlat_to_ccd(x_locs, y_locs, skymap, altitude_km)
    x_locs = result[0] & y_locs = result[1]
  endif else if coordinate_system eq "mag" then begin
    print, "(aurorax_keogram_create_custom) Warning: Magnetic coordinates are not currently supported for this routine."
    return, !null
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

  ; Initialize keogram with a height of n_points-1 and a width of however many frames we have
  if n_channels eq 1 then begin
    keo_arr = intarr((size(images,/dimensions))[-1], n_elements(x_locs)-1)
  endif else begin
    keo_arr = intarr(n_channels, (size(images,/dimensions))[-1], n_elements(x_locs)-1)
  endelse

  ; Iterate through points in pairs of two
  path_counter = 0
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
    if length eq 0 then continue

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
    idx_list = __indices_in_polygon(vertices, [x_max, y_max])
    x_idx_inside = idx_list[0]
    y_idx_inside = idx_list[1]

    ; Make sure data exists for polygon
    if x_idx_inside eq [] or y_idx_inside eq [] then continue

    ; default to median for metric
    metrics = ["mean", "median", "sum"]
    if not keyword_set(metric) then metric = "median"
    if where(metric eq metrics, /null) eq !null then begin
      print, "(aurorax_bounding_box_extract_metric) Error: Metric '"+string(metric)+"' not recognized. Accepted metrics are: "+strjoin(modes, ",")+"."
      return, !null
    endif

    if n_channels eq 1 then begin
      ; Extract metric for every frame from this polygons bounds
      if metric eq "median" then begin
        result = reform(median(images[x_idx_inside,y_idx_inside,*], dimension=1))
      endif else if metric eq "mean" then begin
        result = reform(mean(images[x_idx_inside,y_idx_inside,*], dimension=1))
      endif else if metric eq "sum" then begin
        result = reform(total(images[x_idx_inside,y_idx_inside,*], dimension=1))
      endif

      ; Insert this slice into keogram array
      keo_arr[*,i] = result

      ; Update preview image with keogram slice idx masking if desired
      if keyword_set(show_preview) then begin
        preview_img[x_idx_inside,y_idx_inside] = 255
      endif
    endif else if n_channels eq 3 then begin
      ; Extract metric for every frame from this polygons bounds
      if metric eq "median" then begin
        result = reform(median(median(images[*,x_idx_inside,y_idx_inside,*], dimension=2), dimension=2))
      endif else if metric eq "mean" then begin
        result = reform(mean(mean(images[*,x_idx_inside,y_idx_inside,*], dimension=2), dimension=2))
      endif else if metric eq "sum" then begin
        result = reform(total(total(images[*,x_idx_inside,y_idx_inside,*], 2),2))
      endif

      ; Insert this slice into keogram array
      keo_arr[*,*,i] = result

      ; Update preview image with keogram slice idx masking if desired
      if keyword_set(show_preview) then begin
        preview_img[0,x_idx_inside,y_idx_inside] = 255
        preview_img[1:*,x_idx_inside,y_idx_inside] = 255
      endif
    endif else begin
      print, "[aurorax_keogram_create_custom] Error: Urecognized image shape of "+strcompress(string(image_shape),/remove_all)+"."
      return, !null
    endelse
    path_counter += 1

  endfor

  if path_counter eq 0 then begin
    print, "Could not form keogram path... First ensure that coordinates are within image range. Then try increasing 'width' or " + $
      "decreasing number of points in input coordinates."
    return, !null
  endif

  if keyword_set(show_preview) then begin
    if n_channels eq 1 then begin
      im = image(preview_img, title="Preview of Keogram Slice", rgb_table=0, position=[5,5], /device)
    endif else begin
      im = image(preview_img, title="Preview of Keogram Slice", position=[5,5], /device)
    endelse
  endif

  ; Convert timestamp strings to UT decimal
  ut_decimal = list()

  for i=0,n_elements(time_stamp)-1 do begin
    hh = fix(strmid(time_stamp[i], 11, 2))
    mm = fix(strmid(time_stamp[i], 14, 2))
    ss = fix(strmid(time_stamp[i], 17, 2))
    this_dec = HH+MM/60.0+SS/(60*60.0)
    ut_decimal.add,this_dec
  endfor
  ut_decimal = ut_decimal.toarray()

  ; Return keogram array
  return, {data:keo_arr, timestamp:time_stamp, ut_decimal: ut_decimal, ccd_y:"custom"}
end