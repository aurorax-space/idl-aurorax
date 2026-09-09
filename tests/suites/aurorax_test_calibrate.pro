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
; Tests for the image calibration helpers and the two public calibration
; entry points.
;
; The calibration files are passed in as already-loaded structs, so these
; can all be exercised with small synthetic arrays and hand-built structs --
; no downloads and no IDL save files.
;
; Note that these helpers mutate the array they are handed, since IDL passes
; by reference. Every test below therefore builds a fresh input.

pro aurorax_test_calibrate
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'dark frame calibration'
  ; -----------------------------------------------------------
  ;
  ; three frames at 100/200/300 with darker 5x5 corners; each frame should
  ; have its own corner mean subtracted
  images = intarr(8, 8, 3)
  images[*, *, 0] = 100
  images[*, *, 1] = 200
  images[*, *, 2] = 300
  images[0 : 4, 0 : 4, 0] = 10
  images[0 : 4, 0 : 4, 1] = 20
  images[0 : 4, 0 : 4, 2] = 30
  result = __aurorax_perform_dark_frame_calibration(images, 5)

  atest_not_null, result, 'dark frame calibration returns something'
  atest_equal, result[6, 6, 0], 90, 'frame 0 uses its own corner mean'
  atest_equal, result[6, 6, 1], 180, 'frame 1 uses its own corner mean'
  atest_equal, result[6, 6, 2], 270, 'frame 2 uses its own corner mean'
  atest_equal, result[0, 0, 0], 0, 'the dark corner itself clamps to zero'
  atest_n_elements, size(result, /dimensions), 3, 'a multi frame stack stays three dimensional'

  ; Regression test. The clamp used to be written as
  ;   new_images[where(new_images lt 0)] = 0
  ; and when nothing is negative WHERE returns -1, which IDL reads as "the
  ; last element" -- so a stack with no negative pixels had its very last
  ; pixel silently zeroed. The count is now checked before assigning.
  atest_equal, result[7, 7, 2], 270, $
    'the last pixel of the stack is left alone when no pixel is negative'
  atest_equal, result[7, 7, 1], 180, 'the last pixel of an earlier frame is untouched'

  ; a stack that genuinely does contain negatives still gets clamped
  images = intarr(8, 8, 2) + 100
  images[*, *, 0] = 5
  images[0 : 4, 0 : 4, 0] = 50
  images[0 : 4, 0 : 4, 1] = 10
  result = __aurorax_perform_dark_frame_calibration(images, 5)
  atest_equal, result[6, 6, 0], 0, 'a pixel darker than its corner mean clamps to zero'
  atest_equal, result[6, 6, 1], 90, 'a brighter frame in the same stack is unaffected'

  ; -----------------------------------------------------------
  atest_suite, 'dark frame calibration -- single frame'
  ; -----------------------------------------------------------
  ;
  ; Regression test. The routine reforms a 2D frame up to [cols,rows,1], but
  ; the following `long(images)` dropped the trailing length-1 axis again,
  ; and the frame loop then took its bound from the row count instead of the
  ; frame count and ran off the end of the array. Calibrating a single image
  ; failed outright. The frame count is now captured before the conversion.
  single_frame = intarr(8, 8) + 100
  single_frame[0 : 4, 0 : 4] = 10
  result = __aurorax_perform_dark_frame_calibration(single_frame, 5)
  atest_not_null, result, 'a single 2D frame is calibrated rather than raising'
  atest_n_elements, size(result, /dimensions), 2, 'a single frame comes back two dimensional'
  atest_equal, result[6, 6], 90, 'the corner mean is subtracted from the single frame'
  atest_equal, result[0, 0], 0, 'the dark corner clamps to zero'
  atest_equal, result[7, 7], 90, 'the last pixel is not wrongly zeroed here either'

  ; and through the public entry point
  single_frame = intarr(8, 8) + 100
  single_frame[0 : 4, 0 : 4] = 10
  result = aurorax_calibrate_rego(single_frame)
  atest_not_null, result, 'calibrating a single image through the public entry point works'
  atest_equal, result[6, 6], 90, 'the public entry point applies dark subtraction to it'

  ; -----------------------------------------------------------
  atest_suite, 'flatfield calibration'
  ; -----------------------------------------------------------
  images = fltarr(4, 4, 2) + 10.0
  cal = {flat_field_multiplier: fltarr(4, 4) + 2.0}
  result = __aurorax_perform_flatfield_calibration(images, cal)

  atest_close, result[0, 0, 0], 20.0, 0.0001, 'the multiplier is applied to frame 0'
  atest_close, result[3, 3, 1], 20.0, 0.0001, 'the multiplier is applied to frame 1'

  ; a per-pixel multiplier varies across the frame
  images = fltarr(2, 2, 2) + 10.0
  multiplier = fltarr(2, 2)
  multiplier[0, 0] = 1.0
  multiplier[1, 0] = 2.0
  multiplier[0, 1] = 3.0
  multiplier[1, 1] = 4.0
  result = __aurorax_perform_flatfield_calibration(images, {flat_field_multiplier: multiplier})
  atest_close, result[0, 0, 0], 10.0, 0.0001, 'pixel (0,0) uses its own multiplier'
  atest_close, result[1, 0, 0], 20.0, 0.0001, 'pixel (1,0) uses its own multiplier'
  atest_close, result[1, 1, 0], 40.0, 0.0001, 'pixel (1,1) uses its own multiplier'
  atest_close, result[1, 1, 1], 40.0, 0.0001, 'the same multiplier is reused for the next frame'

  ; unlike the dark frame helper, this one does cope with a single 2D frame,
  ; because it never runs the array through a type conversion
  images = fltarr(4, 4) + 10.0
  result = __aurorax_perform_flatfield_calibration(images, {flat_field_multiplier: fltarr(4, 4) + 2.0})
  atest_close, result[0, 0], 20.0, 0.0001, 'a single 2D frame is handled'
  atest_n_elements, size(result, /dimensions), 2, 'a single frame comes back two dimensional'

  ; -----------------------------------------------------------
  atest_suite, 'rayleighs calibration'
  ; -----------------------------------------------------------
  images = fltarr(2, 2, 2) + 100.0
  cal = {rayleighs_perdn_persecond: 10.0}
  result = __aurorax_perform_rayleighs_calibration(images, cal, 2.0)
  atest_close, result[0, 0, 0], 500.0, 0.001, 'counts scale by rayleighs per DN per second over exposure'
  atest_close, result[1, 1, 1], 500.0, 0.001, 'every frame is scaled the same way'

  ; halving the exposure doubles the result
  images = fltarr(2, 2, 2) + 100.0
  result = __aurorax_perform_rayleighs_calibration(images, cal, 1.0)
  atest_close, result[0, 0, 0], 1000.0, 0.001, 'a shorter exposure yields a larger rayleighs value'

  ; -----------------------------------------------------------
  atest_suite, 'calibrate REGO'
  ; -----------------------------------------------------------
  ;
  ; with no calibration files and dark subtraction disabled, the images
  ; should come back untouched
  images = intarr(8, 8, 2) + 100
  result = aurorax_calibrate_rego(images, /no_dark_subtract)
  atest_equal, result[3, 3, 0], 100, 'no calibration steps leaves the data alone'
  atest_equal, result[7, 7, 1], 100, 'including the last pixel, since the dark step was skipped'

  ; flatfield only
  ;
  ; a single 2D frame is fine here because /no_dark_subtract skips the one
  ; helper that cannot cope with it
  images = fltarr(8, 8) + 10.0
  cal_ff = {flat_field_multiplier: fltarr(8, 8) + 3.0}
  result = aurorax_calibrate_rego(images, cal_flatfield = cal_ff, /no_dark_subtract)
  atest_close, result[2, 2], 30.0, 0.0001, 'the flatfield multiplier is applied'

  ; rayleighs only, exercising the default exposure of 2 seconds
  images = fltarr(4, 4) + 100.0
  cal_r = {rayleighs_perdn_persecond: 10.0}
  result = aurorax_calibrate_rego(images, cal_rayleighs = cal_r, /no_dark_subtract)
  atest_close, result[0, 0], 500.0, 0.001, 'REGO defaults to a 2 second exposure'

  ; an explicit exposure overrides the default
  images = fltarr(4, 4) + 100.0
  result = aurorax_calibrate_rego(images, cal_rayleighs = cal_r, exposure_length_sec = 4.0, /no_dark_subtract)
  atest_close, result[0, 0], 250.0, 0.001, 'an explicit exposure length is honoured'

  ; the full pipeline, dark subtraction included, on a multi frame stack
  images = intarr(8, 8, 3) + 100
  images[0 : 4, 0 : 4, *] = 10
  result = aurorax_calibrate_rego(images)
  atest_equal, result[6, 6, 0], 90, 'the default path applies dark subtraction'

  ; -----------------------------------------------------------
  atest_suite, 'calibrate TREx NIR'
  ; -----------------------------------------------------------
  images = intarr(8, 8, 2) + 100
  result = aurorax_calibrate_trex_nir(images, /no_dark_subtract)
  atest_equal, result[3, 3, 0], 100, 'no calibration steps leaves the data alone'

  ; TREx NIR defaults to a 5 second exposure, which is the only thing that
  ; distinguishes it from the REGO entry point
  images = fltarr(4, 4) + 100.0
  cal_r = {rayleighs_perdn_persecond: 10.0}
  result = aurorax_calibrate_trex_nir(images, cal_rayleighs = cal_r, /no_dark_subtract)
  atest_close, result[0, 0], 200.0, 0.001, 'TREx NIR defaults to a 5 second exposure'

  ; same input, different default -- REGO would give 500 where TREx NIR gives 200
  images = fltarr(4, 4) + 100.0
  rego_result = aurorax_calibrate_rego(images, cal_rayleighs = cal_r, /no_dark_subtract)
  images = fltarr(4, 4) + 100.0
  nir_result = aurorax_calibrate_trex_nir(images, cal_rayleighs = cal_r, /no_dark_subtract)
  atest_not_equal, rego_result[0, 0], nir_result[0, 0], $
    'the two entry points differ only in their default exposure length'

  ; -----------------------------------------------------------
  atest_suite, 'calibration ordering'
  ; -----------------------------------------------------------
  ;
  ; flatfield runs before the rayleighs conversion, so the two multiply
  images = fltarr(4, 4) + 10.0
  cal_ff = {flat_field_multiplier: fltarr(4, 4) + 2.0}
  cal_r = {rayleighs_perdn_persecond: 10.0}
  result = aurorax_calibrate_rego(images, cal_flatfield = cal_ff, cal_rayleighs = cal_r, $
    exposure_length_sec = 1.0, /no_dark_subtract)
  atest_close, result[0, 0], 200.0, 0.001, 'flatfield then rayleighs compose as expected'
end
