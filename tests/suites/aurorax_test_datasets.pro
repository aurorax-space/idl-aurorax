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
; Tests for aurorax_ucalgary_is_read_supported, which tells a caller whether
; aurorax_ucalgary_read knows how to open a given dataset.

pro aurorax_test_datasets
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'read support -- raw imager datasets'
  ; -----------------------------------------------------------
  raw_datasets = [ $
    'THEMIS_ASI_RAW', $
    'REGO_RAW', $
    'TREX_NIR_RAW', $
    'TREX_BLUE_RAW', $
    'TREX_RGB_RAW_NOMINAL', $
    'TREX_RGB_RAW_BURST', $
    'TREX_SPECT_RAW', $
    'SMILE_ASI_RAW']
  for i = 0, n_elements(raw_datasets) - 1 do begin
    atest_true, aurorax_ucalgary_is_read_supported(raw_datasets[i]), $
      raw_datasets[i] + ' is readable'
  endfor

  ; -----------------------------------------------------------
  atest_suite, 'read support -- skymaps'
  ; -----------------------------------------------------------
  skymaps = [ $
    'REGO_SKYMAP_IDLSAV', $
    'THEMIS_ASI_SKYMAP_IDLSAV', $
    'TREX_NIR_SKYMAP_IDLSAV', $
    'TREX_RGB_SKYMAP_IDLSAV', $
    'TREX_BLUE_SKYMAP_IDLSAV', $
    'TREX_SPECT_SKYMAP_IDLSAV', $
    'SMILE_ASI_SKYMAP_IDLSAV']
  for i = 0, n_elements(skymaps) - 1 do begin
    atest_true, aurorax_ucalgary_is_read_supported(skymaps[i]), skymaps[i] + ' is readable'
  endfor

  ; -----------------------------------------------------------
  atest_suite, 'read support -- calibrations'
  ; -----------------------------------------------------------
  calibrations = [ $
    'REGO_CALIBRATION_RAYLEIGHS_IDLSAV', $
    'REGO_CALIBRATION_FLATFIELD_IDLSAV', $
    'TREX_NIR_CALIBRATION_RAYLEIGHS_IDLSAV', $
    'TREX_NIR_CALIBRATION_FLATFIELD_IDLSAV', $
    'TREX_BLUE_CALIBRATION_RAYLEIGHS_IDLSAV', $
    'TREX_BLUE_CALIBRATION_FLATFIELD_IDLSAV']
  for i = 0, n_elements(calibrations) - 1 do begin
    atest_true, aurorax_ucalgary_is_read_supported(calibrations[i]), calibrations[i] + ' is readable'
  endfor

  ; -----------------------------------------------------------
  atest_suite, 'read support -- processed spectrograph'
  ; -----------------------------------------------------------
  atest_true, aurorax_ucalgary_is_read_supported('TREX_SPECT_PROCESSED_V1'), $
    'TREX_SPECT_PROCESSED_V1 is readable'

  ; NOTE: the reader dispatches on the looser prefix TREX_SPECT_PROCESSED_,
  ; but this check uses an exact name match, so a future _V2 would be
  ; reported as unsupported even though the reader would cope with it.
  atest_false, aurorax_ucalgary_is_read_supported('TREX_SPECT_PROCESSED_V2'), $
    'a hypothetical TREX_SPECT_PROCESSED_V2 is not yet in the supported list'

  ; -----------------------------------------------------------
  atest_suite, 'read support -- grid datasets match on substring'
  ; -----------------------------------------------------------
  ;
  ; anything with _GRID_ in the name is handled generically
  atest_true, aurorax_ucalgary_is_read_supported('THEMIS_ASI_GRID_MOSV001'), $
    'a THEMIS grid dataset is readable'
  atest_true, aurorax_ucalgary_is_read_supported('TREX_RGB_GRID_MOSV001'), $
    'a TREx RGB grid dataset is readable'
  atest_true, aurorax_ucalgary_is_read_supported('REGO_GRID_MOSV001'), $
    'a REGO grid dataset is readable'
  atest_true, aurorax_ucalgary_is_read_supported('SOME_FUTURE_GRID_DATASET'), $
    'any dataset with _GRID_ in the name is treated as readable'

  ; -----------------------------------------------------------
  atest_suite, 'read support -- unsupported names'
  ; -----------------------------------------------------------
  atest_false, aurorax_ucalgary_is_read_supported('NOT_A_REAL_DATASET'), $
    'an unknown dataset is not readable'
  atest_false, aurorax_ucalgary_is_read_supported(''), $
    'an empty dataset name is not readable'
  atest_false, aurorax_ucalgary_is_read_supported('THEMIS_ASI'), $
    'a partial name is not readable'

  ; the check is case sensitive on both paths
  atest_false, aurorax_ucalgary_is_read_supported('themis_asi_raw'), $
    'the exact name match is case sensitive'
  atest_false, aurorax_ucalgary_is_read_supported('themis_asi_grid_mosv001'), $
    'the _GRID_ substring match is case sensitive too'
end
