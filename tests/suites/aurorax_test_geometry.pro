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
; Tests for the geometry and timestamp helpers used by the mosaic, keogram
; and field-of-view tools. All pure maths -- no skymaps, no data files.

pro aurorax_test_geometry
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'great circle interpolation'
  ; -----------------------------------------------------------
  ;
  ; the helper returns [lon, lat] pairs; with n_points = 1 the single
  ; interpolated point sits at the halfway mark
  ;
  ; NOTE: asking for one point gives a [2] array rather than [2,1], because
  ; IDL drops a trailing length-1 dimension. Indexing with a trailing 0
  ; works either way, so the value checks below are written that way; the
  ; shape checks use a larger request.
  pts = __aurorax_gc_npts(0.0, 0.0, 0.0, 90.0, 1)
  atest_n_elements, pts, 2, 'a single interpolated point is one lon/lat pair'
  atest_close, pts[1, 0], 45.0, 0.0001, 'halfway from the equator to the pole is 45 degrees latitude'
  atest_close, pts[0, 0], 0.0, 0.0001, 'the meridian is unchanged along that path'

  ; halfway along the equator
  pts = __aurorax_gc_npts(0.0, 0.0, 90.0, 0.0, 1)
  atest_close, pts[0, 0], 45.0, 0.0001, 'halfway along the equator is 45 degrees longitude'
  atest_close, pts[1, 0], 0.0, 0.0001, 'latitude stays on the equator'

  ; several points are evenly spaced
  pts = __aurorax_gc_npts(0.0, 0.0, 0.0, 90.0, 3)
  dims = size(pts, /dimensions)
  atest_n_elements, dims, 2, 'a multi point result is two dimensional'
  atest_equal, dims[0], 2, 'each entry is a lon/lat pair'
  atest_equal, dims[1], 3, 'three interpolated points were produced'
  atest_close, pts[1, 0], 22.5, 0.0001, 'the first quarter point'
  atest_close, pts[1, 1], 45.0, 0.0001, 'the halfway point'
  atest_close, pts[1, 2], 67.5, 0.0001, 'the three quarter point'

  ; -----------------------------------------------------------
  atest_suite, 'great circle interpolation -- endpoints'
  ; -----------------------------------------------------------
  pts = __aurorax_gc_npts(10.0, 20.0, 30.0, 40.0, 3, /include_endpoints)
  atest_equal, (size(pts, /dimensions))[1], 5, 'including endpoints adds two entries'
  atest_close, pts[0, 0], 10.0, 0.0001, 'the first entry is the starting longitude'
  atest_close, pts[1, 0], 20.0, 0.0001, 'the first entry is the starting latitude'
  atest_close, pts[0, 4], 30.0, 0.0001, 'the last entry is the ending longitude'
  atest_close, pts[1, 4], 40.0, 0.0001, 'the last entry is the ending latitude'

  ; -----------------------------------------------------------
  atest_suite, 'haversine distances'
  ; -----------------------------------------------------------
  ;
  ; distance from a point to itself is zero
  d = __aurorax_haversine_distances(51.05, -114.07, 51.05, -114.07)
  atest_close, d, 0.0, 0.001, 'the distance from a point to itself is zero'

  ; one degree of longitude at the equator, against the great circle value
  ; for the sphere the helper assumes (r = 6371 km)
  one_degree = !dpi * 6371000.0d / 180.0d
  d = __aurorax_haversine_distances(0.0, 0.0, 0.0, 1.0)
  atest_close, d, one_degree, 1.0, 'one degree of longitude at the equator'

  ; one degree of latitude is the same on a sphere
  d = __aurorax_haversine_distances(0.0, 0.0, 1.0, 0.0)
  atest_close, d, one_degree, 1.0, 'one degree of latitude'

  ; pole to pole is half the circumference
  ;
  ; the helper works in single precision, which at 2e7 metres resolves to
  ; only a couple of metres, hence the looser tolerance here than on the
  ; shorter distances above
  d = __aurorax_haversine_distances(-90.0, 0.0, 90.0, 0.0)
  atest_close, d, !dpi * 6371000.0d, 10.0, 'pole to pole is half a great circle'

  ; the helper broadcasts across an array of targets
  lats = [0.0, 0.0, 0.0]
  lons = [0.0, 1.0, 2.0]
  d = __aurorax_haversine_distances(0.0, 0.0, lats, lons)
  atest_n_elements, d, 3, 'an array of targets gives an array of distances'
  atest_close, d[0], 0.0, 0.001, 'the first target coincides with the origin'
  atest_close, d[1], one_degree, 1.0, 'the second target is one degree away'
  atest_close, d[2], 2.0 * one_degree, 2.0, 'the third target is two degrees away'

  ; distance is symmetric
  d1 = __aurorax_haversine_distances(51.05, -114.07, 58.75, -94.06)
  d2 = __aurorax_haversine_distances(58.75, -94.06, 51.05, -114.07)
  atest_close, d1, d2, 0.001, 'distance is the same measured in either direction'
  atest_true, d1 gt 0, 'two different sites are a positive distance apart'

  ; -----------------------------------------------------------
  atest_suite, 'cadence detection'
  ; -----------------------------------------------------------
  ts = ['2021-01-01 06:00:00 utc', '2021-01-01 06:00:03 utc', '2021-01-01 06:00:06 utc', $
    '2021-01-01 06:00:09 utc', '2021-01-01 06:00:12 utc']
  atest_equal, __aurorax_determine_cadence(ts), 3, 'a three second series is detected'

  ts = ['2021-01-01 06:00:00 utc', '2021-01-01 06:00:01 utc', '2021-01-01 06:00:02 utc', $
    '2021-01-01 06:00:03 utc', '2021-01-01 06:00:04 utc']
  atest_equal, __aurorax_determine_cadence(ts), 1, 'a one second series is detected'

  ; the modal difference wins, so a single gap does not throw it off
  ts = ['2021-01-01 06:00:00 utc', '2021-01-01 06:00:03 utc', '2021-01-01 06:00:06 utc', $
    '2021-01-01 06:00:15 utc', '2021-01-01 06:00:18 utc', '2021-01-01 06:00:21 utc']
  atest_equal, __aurorax_determine_cadence(ts), 3, 'a gap does not change the detected cadence'

  ; sub-second data reports as burst
  ts = ['2021-01-01 06:00:00.0 utc', '2021-01-01 06:00:00.3 utc', '2021-01-01 06:00:00.6 utc', $
    '2021-01-01 06:00:00.9 utc']
  atest_close, __aurorax_determine_cadence(ts), 1.0 / 3.0, 0.0001, $
    'timestamps sharing a seconds value are treated as burst data'

  ; -----------------------------------------------------------
  atest_suite, 'julian day conversion'
  ; -----------------------------------------------------------
  jd = __aurorax_get_julday('2021-01-01 00:00:00.0 utc')
  atest_close, jd, julday(1, 1, 2021, 0, 0, 0), 0.00001, 'midnight on new year 2021'

  jd = __aurorax_get_julday('2021-06-15 12:30:45.0 utc')
  atest_close, jd, julday(6, 15, 2021, 12, 30, 45), 0.00001, 'an arbitrary timestamp'

  ; the array form matches the scalar form entry for entry
  ts = ['2021-01-01 00:00:00.0 utc', '2021-01-01 06:00:00.0 utc', '2021-01-01 12:00:00.0 utc']
  jd_array = __aurorax_get_julday(ts)
  atest_n_elements, jd_array, 3, 'an array of timestamps gives an array of julian days'
  atest_close, jd_array[0], __aurorax_get_julday(ts[0]), 0.00001, 'array entry 0 matches the scalar call'
  atest_close, jd_array[2], __aurorax_get_julday(ts[2]), 0.00001, 'array entry 2 matches the scalar call'

  ; six hours later is a quarter of a day later
  atest_close, jd_array[1] - jd_array[0], 0.25d, 0.00001, 'six hours is a quarter of a julian day'

  ; -----------------------------------------------------------
  atest_suite, 'field of view contour'
  ; -----------------------------------------------------------
  ;
  ; the non-spectrograph path is pure WGS-84 geometry, so it can be checked
  ; without AACGM or any coefficient files
  site_lat = 51.05
  site_lon = -114.07
  fov = __aurorax_compute_fov_contour(site_lat, site_lon, 110.0, 5.0)

  dims = size(fov, /dimensions)
  atest_equal, dims[0], 361, 'the contour is sampled once per degree of azimuth'
  atest_equal, dims[1], 2, 'each sample is a lat/lon pair'

  ; azimuth 0 and azimuth 360 are the same bearing, so the ring closes
  atest_close, fov[0, 0], fov[360, 0], 0.0001, 'the contour closes in latitude'
  atest_close, fov[0, 1], fov[360, 1], 0.0001, 'the contour closes in longitude'

  ; the contour surrounds the site
  atest_true, min(fov[*, 0]) lt site_lat, 'the contour extends south of the site'
  atest_true, max(fov[*, 0]) gt site_lat, 'the contour extends north of the site'
  atest_true, min(fov[*, 1]) lt site_lon, 'the contour extends west of the site'
  atest_true, max(fov[*, 1]) gt site_lon, 'the contour extends east of the site'

  ; the centroid sits close to the site
  atest_close, mean(fov[*, 0]), site_lat, 0.5, 'the contour is centred on the site latitude'

  ; a higher emission altitude gives a wider field of view
  fov_low = __aurorax_compute_fov_contour(site_lat, site_lon, 110.0, 5.0)
  fov_high = __aurorax_compute_fov_contour(site_lat, site_lon, 230.0, 5.0)
  spread_low = max(fov_low[*, 0]) - min(fov_low[*, 0])
  spread_high = max(fov_high[*, 0]) - min(fov_high[*, 0])
  atest_true, spread_high gt spread_low, 'a higher altitude produces a larger field of view'

  ; a higher elevation cut-off gives a narrower field of view
  fov_strict = __aurorax_compute_fov_contour(site_lat, site_lon, 110.0, 25.0)
  spread_strict = max(fov_strict[*, 0]) - min(fov_strict[*, 0])
  atest_true, spread_strict lt spread_low, 'a stricter elevation limit narrows the field of view'
end
