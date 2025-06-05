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

function __aurorax_gc_npts, lon_1, lat_1, lon_2, lat_2, n_points, include_endpoints = include_endpoints
  ; Helper function that interpolates a curve along a great circle
  ; between two points on a sphere. Used to determine spectrogaph fovs

  ; Convert to radians
  conv = !dpi/180d
  lon1 = lon_1*conv
  lat1 = lat_1*conv
  lon2 = lon_2*conv
  lat2 = lat_2*conv

  ; 3-D unit vectors
  v1 = [cos(lat1)*cos(lon1), cos(lat1)*sin(lon1), sin(lat1)]
  v2 = [cos(lat2)*cos(lon2), cos(lat2)*sin(lon2), sin(lat2)]

  omega = acos(total(v1*v2))

  ; get number of intermediate points
  if keyword_set(include_endpoints) then begin
    res = dblarr(2, n_points+2)
    res[*,0] = [lon1/conv, lat1/conv]
    res[*,-1] = [lon2/conv, lat2/conv]
    idx = 1
  endif else begin
    res = dblarr(2, n_points)
    idx = 0
  endelse

  for k = 1, n_points do begin
    f = k / (n_points + 1d)
    a = sin((1d - f)*omega) / sin(omega)
    b = sin(f*omega) / sin(omega)
    v = a*v1 + b*v2
    v = v / sqrt(total(v^2)) ; re-normalise
    lat = asin(v[2]) / conv
    lon = atan(v[1], v[0]) / conv
    res[*,idx] = [lon, lat]
    idx += 1
  endfor

  return, res
end

function __aurorax_compute_fov_contour, lat, lon, height_km, min_elevation, spectrograph = spectrograph
  ; helper function that does the actual computations for
  ; mapping out an ASI or spectrograph FOV

  ; Ellipsoid Parameters for WGS 1984 model of Earth
  a = 6378137.0
  f1 = 298.257223563

  f = 1.0 / f1
  e2 = f * (2.0 - f)
  e_minus = (1.0 - f)^2
  deg2rad = !dpi / 180.0
  rad2deg = 180.0 / !dpi

  ; Convert from geodetic coordinates
  h = 0.0
  phi = lat * deg2rad
  n_phi = a / sqrt(1.0 - e2 * sin(phi)^2)

  ; To Cartesian coordinates
  lam = lon * deg2rad
  c_phi = cos(phi)
  s_phi = sin(phi)
  x = (n_phi + h) * c_phi * cos(lam)
  y = (n_phi + h) * c_phi * sin(lam)
  z = (e_minus * n_phi + h) * s_phi

  result = [x, y, z]

  s_lam = sin(lam)
  c_lam = cos(lam)
  east = [-s_lam, c_lam, 0.0]
  down = [-c_phi * c_lam, -c_phi * s_lam, -s_phi]
  north = [-c_lam * s_phi, -s_lam * s_phi, c_phi]

  el = min_elevation * deg2rad

  ; Non-Spherical Earth
  re = 6371.2
  rho0 = height_km * (2 * re + height_km) / (2 * re * sin(min_elevation * deg2rad))
  rho = height_km * (2 * re + height_km) / (2 * re * sin(min_elevation * deg2rad) + rho0)

  ; Create empty array for lat/lon at every 1deg along 360deg azimuth range
  azimuth_angle = findgen(361, increment=1.0)
  fov_latlon = make_array(n_elements(azimuth_angle), 2, value=0.0)

  for idx=0, n_elements(azimuth_angle)-1 do begin

    ; Adjust aim for this point along FOV
    az = azimuth_angle[idx] * deg2rad
    aim = north * cos(az) * cos(el) + east * sin(az) * cos(el) - down * sin(el)

    ; Map from Cartesian back to geodetic for this iteration's point
    point_cartesian = result + aim * rho * (1.0 * 10^3)
    x = point_cartesian[0]
    y = point_cartesian[1]
    z = point_cartesian[2]

    lam = atan(y, x)
    r = sqrt(x^2 + y^2)

    phi = 0.0
    n_phi = 0.0

    for i=0, 4 do begin
      phi = atan((z + n_phi * e2 * sin(phi)) / r)
      n_phi = a / sqrt(1.0 - e2 * (sin(phi))^2)
    endfor

    h = r / cos(phi) - n_phi

    point_lat = phi * rad2deg
    point_lon = lam * rad2deg
    
    fov_latlon[idx, 0] = point_lat
    fov_latlon[idx, 1] = point_lon

  endfor

  ; If we're working on an ASI FoV we are done, for spectrograph there's additional work
  if keyword_set(spectrograph) then begin
    ; note from here on we are assuming a spherical
    ; Earth, unlike in the above code

    ; We need to find the line that bisects the current
    ; fov contour that is aligned with magnetic north
    !null = aacgm_v2_setnow()
    mag_pos = cnvcoord_v2(transpose([[fov_latlon[*,0]], [fov_latlon[*,1]], [fov_latlon[*,1]*0.0]]), verbose=-1)
    mag_lat = reform(mag_pos[0,*])

    mag_north_bin = where(mag_lat eq max(mag_lat,/nan))
    mag_south_bin = where(mag_lat eq min(mag_lat,/nan))

    ; dynamically determine number of bins based on elevation threshold
    n_points = 180 - 2 * (fix(min_elevation)-1)

    ; Get lat/lon of min/max bins
    lat_max = fov_latlon[mag_north_bin,0]
    lat_min = fov_latlon[mag_south_bin,0]
    lon_max = fov_latlon[mag_north_bin,1]
    lon_min = fov_latlon[mag_south_bin,1]

    ; Get contour along great circle that connects these two points
    result = __aurorax_gc_npts(lon_min, lat_min, lon_max, lat_max, n_points, /include_endpoints)
    lons = reform(result[0,*])
    lats = reform(result[1,*])

    ; re-initialize fov coordinate array and fill
    fov_latlon = make_array(n_points+2, 2, value=0.0)
    fov_latlon[*,0] = lats
    fov_latlon[*,1] = lons
  endif

  return, fov_latlon
end

;+
; :Description:
;       Integrate spectrograph data to obtain absolute intensity, for a given common
;       auroral emission or a manually selected wavelength band.
;
; :Parameters:
;       site_lat: in, required, Float
;         the geographic latitude of the site / instrument location
;       site_lon: in, required, Float
;         the geographic longitude of the site / instrument location
;       altitude_km: in, required, Float
;         The altitude (in kilometers) at which the image data should be
;
; :Keywords:
;       min_elevation: in, optional, Float
;         the elevation angle in degrees, from the horizon, to map the FoV at
;       site_name: in, optional, String
;         a string giving the site name / label associated with FoV
;       spectrograph: in, optional, Boolean
;         if true, specifies that the FoV should be computed for a meridian
;         scanning spectrograph, as opposed ot an ASI (the default)
;       color: in, optional, Long Integer
;         long integer giving the color to plot in (default is 0 i.e. black)
;       linestyle: in, optional, Integer
;         integer giving IDL linestyle (default is 0, i.e. solid)
;       thick: in, optional, Integer
;         integer giving line thickness for any lines plotted (default is 1)
;       label_site: in, optional, Boolean
;         label FoV with the parameter supplied by site_name
;       label_color: in, optional, Long Integer
;         long integer giving the color to label in (default is 0 i.e. black)
;
; :Examples:
;       ????????????????????????????????????????????
;+
pro aurorax_fov_oplot, $
  site_lat, $
  site_lon, $
  altitude_km, $
  min_elevation = min_elevation, $
  site_name = site_name, $
  spectrograph = spectrograph, $
  color = color, $
  linestyle = linestyle, $
  thick = thick, $
  label_site = label_site, $
  label_color = label_color

  ; First, check that required inputs are valid
  
  ; convert scalar inputs to arrays
  if isa(site_lat, /scalar) then site_lat = [site_lat]
  if isa(site_lon, /scalar) then site_lon = [site_lon]
  if n_elements(site_lat) ne n_elements(site_lon) then begin
    print, n_elements(site_lat)
    print, n_elements(site_lon)
    stop
    print, '[aurorax_oplot_fov] Error: ensure ''site_lat'' and ''site_lat'' have the same number of elements'
    goto, error_jump
  endif

  ; Check site_name if supplied and conver to array if scalar
  if keyword_set(site_name) then begin
    if not isa(site_name, /string) then begin
      print, '[aurorax_oplot_fov] Error: ensure ''site_name'' is of type String'
      goto, error_jump
    endif
    if isa(site_name, /scalar) then site_name = [site_name]
    if n_elements(site_lat) ne n_elements(site_name) then begin
      print, '[aurorax_oplot_fov] Error: ensure ''site_name'' has the same number of elements as ''site_lat'' and ''site_lat'''
      goto, error_jump
    endif
  endif else begin
    if keyword_set(label_site) then begin
      print, '[aurorax_oplot_fov] Error: ensure ''site_name'' is passed when using keyword /label_site'''
      goto, error_jump
    endif
  endelse
  
  ; Check input lat
  if not isa(site_lat, /float) then begin
    if ~ isa(site_lat, /int) then begin
      print, '[aurorax_oplot_fov] Error: input ''site_lat'' must be of type Float or Int'
      goto, error_jump
    endif
    site_lat = float(site_lat)
  endif
  foreach sl, site_lat do begin
    if (sl gt 90.0) or (sl lt -90.0) then begin
      print, '[aurorax_oplot_fov] Error: ensure ''site_lat'' is within the valid range [-90,90]'
      goto, error_jump
    endif
  endforeach

  ; Check input lon
  if not isa(site_lon, /float) then begin
    if not isa(site_lon, /int) then begin
      print, '[aurorax_oplot_fov] Error: input ''site_lon'' must be of type Float or Int'
      goto, error_jump
    endif
    site_lon = float(site_lon)
  endif
  foreach sl, site_lon do begin
    if (sl gt 180.0) or (sl lt -180.0) then begin
      print, '[aurorax_oplot_fov] Error: ensure ''site_lon'' is within the valid range [-90,90]'
      goto, error_jump
    endif
  endforeach

  ; Check input altitude
  if not isa(altitude_km, /float) then begin
    if not isa(altitude_km, /int) then begin
      print, '[aurorax_oplot_fov] Error: input ''altitude_km'' must be of type Float or Int'
      goto, error_jump
    endif
    altitude_km = float(altitude_km)
  endif
  if (altitude_km gt 2500.0) or (altitude_km lt 5.0) then begin
    print, '[aurorax_oplot_fov] Error: ensure ''altitude_km'' is within the valid range [5,2500]'
    goto, error_jump
  endif

  if isa(min_elevation) then begin
    if not isa(min_elevation, /float) then begin
      if not isa(min_elevation, /int) then begin
        print, '[aurorax_oplot_fov] Error: input ''min_elevation'' must be of type Float or Int'
        goto, error_jump
      endif
      min_elevation = float(min_elevation)
    endif
    if (min_elevation ge 90.0) or (min_elevation lt 5.0) then begin
      print, '[aurorax_oplot_fov] Error: ensure ''altitude_km'' is within the valid range [5,90)'
      goto, error_jump
    endif
  endif else min_elevation = 5.0
  
  ; Make sure that all plot parameters are accepted
  if keyword_set(color) then begin
    if not isa(color, /scalar, /number) or color lt 0 or color gt aurorax_get_decomposed_color([255, 255, 255]) then begin
      print, '[aurorax_oplot_fov] Error: ''color'' must be a scalar specifying a valid ' + $
        'long integer decomposed color. Use aurorax_get_decomposed_color to obtain color ' + $
        'integer from RGB triple.'
      goto, error_jump
    endif
  endif else color = 0
  if keyword_set(thick) then begin
    if not isa(thick, /scalar, /number) or thick lt 0 then begin
      print, '[aurorax_oplot_fov] Error: ''thick'' must be a positive integer ' + $
        'specifying the contour thickness.'
      goto, error_jump
    endif
  endif else thick = 1
  if keyword_set(linestyle) then begin
    if not isa(linestyle, /scalar, /number) or linestyle lt 0 or linestyle gt 6 then begin
      print, '[aurorax_oplot_fov] Error: ''linestyle'' must be an integer ' + $
        'from 0-6. (See IDL built-in linestyles).'
      goto, error_jump
    endif
  endif else linestyle=0

  ; Ensure label parameters are accepted
  if keyword_set(label_color) then begin
    if not isa(label_color, /scalar, /number) or label_color lt 0 or label_color gt aurorax_get_decomposed_color([255, 255, 255]) then begin
      print, '[aurorax_oplot_fov] Error: ''label_color'' must be a scalar specifying a valid ' + $
        'long integer decomposed color. Use aurorax_get_decomposed_color to obtain color ' + $
        'integer from RGB triple.'
      goto, error_jump
    endif
  endif else label_color=0

  for site_idx=0, n_elements(site_lat)-1 do begin

    lat = site_lat[site_idx]
    lon = site_lon[site_idx]

    if keyword_set(spectrograph) then begin
      contour_latlon = __aurorax_compute_fov_contour(lat, lon, altitude_km, min_elevation, /spectrograph)
    endif else begin
      contour_latlon = __aurorax_compute_fov_contour(lat, lon, altitude_km, min_elevation)
    endelse
    
    contour_lats = contour_latlon[*,0]
    contour_lons = contour_latlon[*,1]

    plots, contour_lons, contour_lats, color = color, linestyle = linestyle, thick = thick
    
    if keyword_set(label_site) eq 1 then begin
      site_uid = site_name[site_idx]
      !p.font = 1
      device, set_font="Helvetica Bold", /tt_font, set_character_size=[12,12]
      xyouts, mean(contour_lons), mean(contour_lats), site_uid, color=label_color, alignment=0.5
      !p.font = -1
    endif
  endfor
  error_jump:
end