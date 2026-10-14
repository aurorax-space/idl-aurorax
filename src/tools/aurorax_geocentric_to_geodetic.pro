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
;   Convert geocentric latitudes and longitudes to geodetic (WGS84).
;
;   Spacecraft locations and B-trace footprints from the AuroraX search engine are
;   NASA SSCWeb values, which use a spherical Earth of radius 6371.2 km, so their
;   latitudes are geocentric; the footprints are traced to 100 km altitude. Skymaps,
;   observatory coordinates and map projections are geodetic, so convert before
;   overlaying. At auroral latitudes the difference is about 0.15 degrees (15-20 km).
;
; :Arguments:
;   lats: in, required, Float or Array
;     geocentric latitude(s), for example the nbtrace.lat values of ephemeris records
;   lons: in, required, Float or Array
;     geocentric longitude(s), same number of elements as lats
;
; :Keywords:
;   altitude_km: in, optional, Float
;     altitude of the points above the 6371.2 km sphere, in km (default is 100.0,
;     the SSCWeb footprint altitude)
;
; :Returns:
;   Struct with the tags lats and lons, the geodetic values as double arrays,
;   or !null if the inputs are invalid
;
; :Examples:
;   geod = aurorax_geocentric_to_geodetic(footprint_lats, footprint_lons)
;   plots, geod.lons, geod.lats
;-
function aurorax_geocentric_to_geodetic, lats, lons, altitude_km = altitude_km
  ; default to the SSCWeb footprint altitude
  if not isa(altitude_km) then altitude_km = 100.0

  ; check inputs
  geoc_lats = double(lats)
  geoc_lons = double(lons)
  if n_elements(geoc_lats) ne n_elements(geoc_lons) then begin
    print, '[aurorax_geocentric_to_geodetic] Error: lats and lons must have the same number of elements.'
    return, !null
  endif

  ; Ellipsoid Parameters for WGS 1984 model of Earth (as in aurorax_fov_oplot)
  a = 6378137.0d
  f1 = 298.257223563d
  f = 1.0d / f1
  e2 = f * (2.0d - f)
  deg2rad = !dpi / 180.0d
  rad2deg = 180.0d / !dpi

  ; SSCWeb uses a spherical Earth of radius 6371.2 km
  r_m = (6371.2d + altitude_km) * 1000.0d

  ; spherical geocentric to Cartesian, in metres
  lat_rad = geoc_lats * deg2rad
  lon_rad = geoc_lons * deg2rad
  x = r_m * cos(lat_rad) * cos(lon_rad)
  y = r_m * cos(lat_rad) * sin(lon_rad)
  z = r_m * sin(lat_rad)

  ; Cartesian to geodetic, iterating on the latitude (same scheme as aurorax_fov_oplot);
  ; the height is discarded. p is floored so the poles do not divide by zero.
  lam = atan(y, x)
  p = sqrt(x ^ 2 + y ^ 2) > 1d-9
  phi = atan(z, p)
  n_phi = a / sqrt(1.0d - e2 * sin(phi) ^ 2)
  for i = 0, 9 do begin
    phi = atan((z + n_phi * e2 * sin(phi)) / p)
    n_phi = a / sqrt(1.0d - e2 * sin(phi) ^ 2)
  endfor

  return, {lats: phi * rad2deg, lons: lam * rad2deg}
end
