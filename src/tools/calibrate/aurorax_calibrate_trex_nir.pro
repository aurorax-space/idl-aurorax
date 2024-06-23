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

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_CALIBRATE_TREX_NIR
;
; PURPOSE:
;       Calibrate one or more TREx NIR images.
;
; EXPLANATION:
;       Apply a number of calibrations, such as dark frame subtraction,
;       flatfield calibration, and calibration to Rayleighs, one can
;       apply only certain calibration steps if desired.
;
; CALLING SEQUENCE:
;       aurorax_calibrate_trex_nir(images, cal_flatfield, cal_rayleighs)
;
; PARAMETERS:
;       images                  array of images to calibrate
;       cal_flatfield           the flatfield calibration to use (if desired), usually a result of reading a calibration file, optional
;       cal_rayleighs           the rayleighs calibration to use (if desired), usually a result of reading a calibration file, optional
;       exposure_length_sec     the exposure length for the image data being calibrated, optional (defaults to 5.0)
;
; KEYWORDS:
;       /NO_DARK_SUBTRACT       omits the dark subtraction step of the calibration process
;
; OUTPUT
;       calibrated image data
;
; OUTPUT TYPE:
;       array
;
; EXAMPLES:
;       rayleighs_images = aurorax_calibrate_trex_nir(images, cal_flatfield=flatfield_cal, cal_rayleighs=rayleighs_cal)
;       bg_subtracted_images = aurorax_calibrate_trex_nir(images)
;+
;-------------------------------------------------------------
function aurorax_calibrate_trex_nir, images, cal_flatfield=cal_flatfield, cal_rayleighs=cal_rayleighs, exposure_length_sec=exposure_length_sec, no_dark_subtract=no_dark_subtract

  calibrated_images = images

  ; Default exposure of 5 seconds
  if not keyword_set(exposure_length_sec) then exposure_length_sec = 5.0

  ; Skip dark frame subtraction if desired
  if keyword_set(no_dark_subtract) then goto, skip_dark_frame

  ; Perform dark frame subtraction
  calibrated_images = __perform_dark_frame_calibration(calibrated_images, 5)
  skip_dark_frame:

  ; Skip flatfield calibration if desired
  if not keyword_set(cal_flatfield) then goto, skip_cal_flatfield

  ; Perform flatfield calibration
  calibrated_images = __perform_flatfield_calibration(calibrated_images, cal_flatfield)
  skip_cal_flatfield:

  ; Skip rayleighs calibration if desired
  if not keyword_set(cal_rayleighs) then goto, skip_cal_rayleighs

  ; Perform flatfield calibration
  calibrated_images = __perform_rayleighs_calibration(calibrated_images, cal_rayleighs, exposure_length_sec)
  skip_cal_rayleighs:

  return, calibrated_images
end