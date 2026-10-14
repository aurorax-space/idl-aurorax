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
;
; Tests for aurorax_geocentric_to_geodetic(), the SSCWeb geocentric to WGS84
; geodetic conversion applied to ephemeris footprints before plotting. Pure maths.

pro aurorax_test_geocentric_to_geodetic
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'geocentric to geodetic -- known value'
  ; -----------------------------------------------------------
  ;
  ; at 60 N and 100 km the WGS84 geodetic latitude sits about 0.164 degrees
  ; poleward of the geocentric latitude; the longitude is untouched
  geod = aurorax_geocentric_to_geodetic([60.0d], [-120.0d], altitude_km = 100.0)
  atest_has_tag, geod, 'lats', 'the result has a lats tag'
  atest_has_tag, geod, 'lons', 'the result has a lons tag'
  atest_close, geod.lats[0], 60.164d, 0.01d, 'geodetic latitude at 60 N and 100 km'
  atest_close, geod.lons[0], -120.0d, 1d-6, 'the longitude is unchanged'

  ; -----------------------------------------------------------
  atest_suite, 'geocentric to geodetic -- invariants'
  ; -----------------------------------------------------------
  geod = aurorax_geocentric_to_geodetic([0.0d, 90.0d], [45.0d, 0.0d])
  atest_n_elements, geod.lats, 2, 'one output latitude per input'
  atest_close, geod.lats[0], 0.0d, 1d-9, 'the equator maps to the equator'
  atest_close, geod.lats[1], 90.0d, 1d-9, 'the pole maps to the pole'

  ; -----------------------------------------------------------
  atest_suite, 'geocentric to geodetic -- input checks'
  ; -----------------------------------------------------------
  atest_null, aurorax_geocentric_to_geodetic([60.0d, 61.0d], [-120.0d]), 'mismatched lengths return !null'
end
