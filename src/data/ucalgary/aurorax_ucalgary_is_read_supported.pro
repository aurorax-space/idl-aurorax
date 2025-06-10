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
;       Determine if a given dataset is supported in the aurorax_ucalgary_read()
;       function. This function will return 0 for False, 1 for True.
;
;       Some datasets provided by UCalgary require special readfile routines. This
;       function provides the ability to programmatically determine if a dataset
;       is supported in the aurorax_ucalgary_read() function.
;
;       Some datasets are simple enough for special read routines to be needed. For
;       example, 'THEMIS_ASI_DAILY_KEOGRAM_JPG', can be read in using the built-in
;       READ_JPEG procedure.
;
; :Parameters:
;       dataset_name: in, required, String
;         name of the dataset to check for read support
;
; :Returns:
;       Integer
;
; :Examples:
;       supported = aurorax_ucalgary_is_read_supported('THEMIS_ASI_RAW')
;       supported = aurorax_ucalgary_is_read_supported('THEMIS_ASI_DAILY_KEOGRAM_JPG')
;+
function aurorax_ucalgary_is_read_supported, dataset_name
  ; check for grid data first
  if dataset_name.contains('_GRID_') eq 1 then return, 1

  supported_datasets = list( $
    'THEMIS_ASI_RAW', $
    'REGO_RAW', $
    'TREX_NIR_RAW', $
    'TREX_BLUE_RAW', $
    'TREX_RGB_RAW_NOMINAL', $
    'TREX_RGB_RAW_BURST', $
    'REGO_SKYMAP_IDLSAV', $
    'THEMIS_ASI_SKYMAP_IDLSAV', $
    'TREX_NIR_SKYMAP_IDLSAV', $
    'TREX_RGB_SKYMAP_IDLSAV', $
    'TREX_BLUE_SKYMAP_IDLSAV', $
    'REGO_CALIBRATION_RAYLEIGHS_IDLSAV', $
    'REGO_CALIBRATION_FLATFIELD_IDLSAV', $
    'TREX_NIR_CALIBRATION_RAYLEIGHS_IDLSAV', $
    'TREX_NIR_CALIBRATION_FLATFIELD_IDLSAV', $
    'TREX_BLUE_CALIBRATION_RAYLEIGHS_IDLSAV', $
    'TREX_BLUE_CALIBRATION_FLATFIELD_IDLSAV', $
    'TREX_SPECT_RAW', $
    'TREX_SPECT_PROCESSED_V1', $
    'TREX_SPECT_SKYMAP_IDLSAV', $
    'SMILE_ASI_RAW', $
    'SMILE_ASI_SKYMAP_IDLSAV')

  ; check
  supported = supported_datasets.where(dataset_name)
  if (isa(supported) eq 1) then begin
    ; found match
    return, 1
  endif else begin
    ; did not find match, null was returned from the where call
    return, 0
  endelse
end
