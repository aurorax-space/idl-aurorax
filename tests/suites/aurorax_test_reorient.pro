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
; Tests for the per-instrument image reorientation applied on read.
;
; Every instrument stores its frames in a slightly different orientation,
; and the reader flips them into a common one. Getting a flip wrong would
; silently mirror somebody's data, so each instrument's rule is pinned here
; with a small asymmetric array where every flip is visible.

pro aurorax_test_reorient
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'reorient ASI images -- single channel'
  ; -----------------------------------------------------------
  ;
  ; a 2x2 frame whose corners are all different, so a flip on either axis
  ; produces a distinguishable result:
  ;
  ;   [0,1]=3  [1,1]=4
  ;   [0,0]=1  [1,0]=2
  make_frame = intarr(2, 2, 1)
  make_frame[0, 0, 0] = 1
  make_frame[1, 0, 0] = 2
  make_frame[0, 1, 0] = 3
  make_frame[1, 1, 0] = 4

  ; THEMIS flips vertically (axis 2)
  data = make_frame
  result = __reorient_asi_images('THEMIS_ASI_RAW', data)
  atest_equal, result[0, 0, 0], 3, 'THEMIS flips vertically'
  atest_equal, result[1, 1, 0], 2, 'THEMIS leaves the horizontal axis alone'

  ; TREx Blue and TREx NIR do the same
  data = make_frame
  atest_equal, (__reorient_asi_images('TREX_BLUE_RAW', data))[0, 0, 0], 3, 'TREx Blue flips vertically'
  data = make_frame
  atest_equal, (__reorient_asi_images('TREX_NIR_RAW', data))[0, 0, 0], 3, 'TREx NIR flips vertically'

  ; REGO flips both ways, so the corner opposite is what ends up at the origin
  data = make_frame
  result = __reorient_asi_images('REGO_RAW', data)
  atest_equal, result[0, 0, 0], 4, 'REGO flips both horizontally and vertically'
  atest_equal, result[1, 1, 0], 1, 'the opposite corner swaps in as well'

  ; an unrecognised dataset is passed through untouched
  data = make_frame
  result = __reorient_asi_images('SOME_OTHER_DATASET', data)
  atest_equal, result[0, 0, 0], 1, 'an unknown dataset is left as it was'
  atest_equal, result[1, 1, 0], 4, 'no axis is flipped for an unknown dataset'

  ; -----------------------------------------------------------
  atest_suite, 'reorient ASI images -- colour'
  ; -----------------------------------------------------------
  ;
  ; RGB data is [channel, col, row, frame], so the vertical axis is 3
  rgb = intarr(3, 2, 2, 1)
  rgb[0, 0, 0, 0] = 1
  rgb[0, 0, 1, 0] = 2

  data = rgb
  result = __reorient_asi_images('TREX_RGB_RAW_NOMINAL', data)
  atest_equal, result[0, 0, 0, 0], 2, 'TREx RGB nominal flips on the row axis'

  data = rgb
  result = __reorient_asi_images('TREX_RGB_RAW_BURST', data)
  atest_equal, result[0, 0, 0, 0], 2, 'TREx RGB burst flips the same way'

  data = rgb
  result = __reorient_asi_images('SMILE_ASI_RAW', data)
  atest_equal, result[0, 0, 0, 0], 2, 'SMILE ASI flips the same way'

  ; -----------------------------------------------------------
  atest_suite, 'reorient skymaps'
  ; -----------------------------------------------------------
  ;
  ; every skymap gets a vertical flip regardless of instrument
  make_skymap = { $
    full_elevation: [[1, 2], [3, 4]], $
    full_azimuth: [[1, 2], [3, 4]], $
    full_map_latitude: [[1, 2], [3, 4]], $
    full_map_longitude: [[1, 2], [3, 4]]}

  skymap = make_skymap
  result = __reorient_skymaps('THEMIS_ASI_SKYMAP_IDLSAV', skymap)
  atest_equal, result.full_elevation[0, 0], 3, 'a THEMIS skymap is flipped vertically'
  atest_equal, result.full_azimuth[0, 0], 3, 'azimuth is flipped alongside elevation'
  atest_equal, result.full_map_latitude[0, 0], 3, 'latitude is flipped too'
  atest_equal, result.full_map_longitude[0, 0], 3, 'longitude is flipped too'

  ; REGO skymaps get a horizontal flip on top of that, matching what is done
  ; to the raw REGO frames
  skymap = make_skymap
  result = __reorient_skymaps('REGO_SKYMAP_IDLSAV', skymap)
  atest_equal, result.full_elevation[0, 0], 4, 'a REGO skymap is flipped on both axes'
  atest_equal, result.full_azimuth[0, 0], 4, 'REGO azimuth gets both flips as well'

  ; spectrograph skymaps flip elevation, latitude and longitude on the first
  ; axis, but deliberately not azimuth
  skymap = make_skymap
  result = __reorient_skymaps('TREX_SPECT_SKYMAP_IDLSAV', skymap)
  atest_equal, result.full_elevation[0, 0], 4, 'spectrograph elevation gets the extra flip'
  atest_equal, result.full_map_latitude[0, 0], 4, 'spectrograph latitude gets the extra flip'
  atest_equal, result.full_map_longitude[0, 0], 4, 'spectrograph longitude gets the extra flip'
  atest_equal, result.full_azimuth[0, 0], 3, 'spectrograph azimuth is only flipped vertically'

  ; -----------------------------------------------------------
  atest_suite, 'reorient calibration files'
  ; -----------------------------------------------------------
  make_cal = {flat_field_multiplier: [[1, 2], [3, 4]]}

  cal = make_cal
  result = __reorient_calibration('REGO_CALIBRATION_FLATFIELD_IDLSAV', cal)
  atest_equal, result.flat_field_multiplier[0, 0], 4, 'a REGO flatfield is flipped on both axes'

  cal = make_cal
  result = __reorient_calibration('TREX_NIR_CALIBRATION_FLATFIELD_IDLSAV', cal)
  atest_equal, result.flat_field_multiplier[0, 0], 3, 'a TREx NIR flatfield is flipped vertically'

  ; rayleighs calibrations have no image to flip, so nothing happens
  cal = make_cal
  result = __reorient_calibration('REGO_CALIBRATION_RAYLEIGHS_IDLSAV', cal)
  atest_equal, result.flat_field_multiplier[0, 0], 1, 'a rayleighs calibration is left alone'

  cal = make_cal
  result = __reorient_calibration('SOMETHING_ELSE', cal)
  atest_equal, result.flat_field_multiplier[0, 0], 1, 'an unknown calibration is left alone'
end
