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
; Tests for the TREx ATM model output flag helpers, and for the model
; version guards on the two model entry points.

;+
; Sum the values of a flags hash, so a test can say "how many are on".
;-
function __atest_flag_sum, flags
  compile_opt idl2

  total_on = 0l
  foreach value, flags, key do total_on = total_on + long(value)
  return, total_on
end

pro aurorax_test_atm_flags
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'ATM forward output flags'
  ; -----------------------------------------------------------
  flags = aurorax_atm_forward_get_output_flags()
  atest_equal, typename(flags), 'HASH', 'the forward flags come back as a hash'
  atest_true, n_elements(flags) gt 0, 'the forward flags hash is not empty'
  atest_equal, __atest_flag_sum(flags), 0, 'every forward flag defaults to off'

  ; the flags a caller is most likely to reach for
  expected_keys = [ $
    'altitudes', $
    'height_integrated_rayleighs_1304', $
    'height_integrated_rayleighs_1356', $
    'height_integrated_rayleighs_4278', $
    'height_integrated_rayleighs_5577', $
    'height_integrated_rayleighs_6300', $
    'height_integrated_rayleighs_8446', $
    'height_integrated_rayleighs_smile_uvi_lbh', $
    'emission_4278', $
    'emission_5577', $
    'emission_smile_uvi_lbh', $
    'plasma_electron_density', $
    'plasma_pedersen_conductivity', $
    'plasma_hall_conductivity', $
    'neutral_temperature']
  for i = 0, n_elements(expected_keys) - 1 do begin
    atest_has_key, flags, expected_keys[i], 'forward flags include ' + expected_keys[i]
  endfor

  ; the 1.9.0 renames -- these are the names that replaced the older
  ; height_integrated_rayleighs_lbh, emission_lbh and
  ; plasma_pederson_conductivity spellings
  atest_false, flags.hasKey('height_integrated_rayleighs_lbh'), $
    'the pre-1.9.0 height_integrated_rayleighs_lbh name is gone'
  atest_false, flags.hasKey('emission_lbh'), 'the pre-1.9.0 emission_lbh name is gone'
  atest_false, flags.hasKey('plasma_pederson_conductivity'), $
    'the misspelled plasma_pederson_conductivity name is gone'

  ; -----------------------------------------------------------
  atest_suite, 'ATM forward output flags -- set_all_true'
  ; -----------------------------------------------------------
  n_keys = n_elements(flags)
  flags = aurorax_atm_forward_get_output_flags(/set_all_true)
  atest_equal, n_elements(flags), n_keys, '/set_all_true does not change the key set'
  atest_equal, __atest_flag_sum(flags), n_keys, '/set_all_true turns every flag on'

  ; -----------------------------------------------------------
  atest_suite, 'ATM forward output flags -- height integrated rayleighs only'
  ; -----------------------------------------------------------
  flags = aurorax_atm_forward_get_output_flags(/enable_only_height_integrated_rayleighs)
  atest_equal, n_elements(flags), n_keys, 'the shortcut does not change the key set'

  n_on = __atest_flag_sum(flags)
  atest_true, n_on gt 0, 'the shortcut turns some flags on'
  atest_true, n_on lt n_keys, 'the shortcut does not turn everything on'

  ; every flag that is on must be a height integrated rayleighs flag, and
  ; every height integrated rayleighs flag must be on
  all_hir_on = 1
  only_hir_on = 1
  foreach value, flags, key do begin
    is_hir = strmid(key, 0, 28) eq 'height_integrated_rayleighs_'
    if (is_hir and value eq 0) then all_hir_on = 0
    if (~is_hir and value ne 0) then only_hir_on = 0
  endforeach
  atest_true, all_hir_on, 'every height integrated rayleighs flag is on'
  atest_true, only_hir_on, 'nothing outside height integrated rayleighs is on'
  atest_equal, flags['altitudes'], 0, 'altitudes specifically stays off'

  ; -----------------------------------------------------------
  atest_suite, 'ATM inverse output flags'
  ; -----------------------------------------------------------
  flags = aurorax_atm_inverse_get_output_flags()
  atest_equal, typename(flags), 'HASH', 'the inverse flags come back as a hash'
  atest_equal, __atest_flag_sum(flags), 0, 'every inverse flag defaults to off'
  atest_has_key, flags, 'altitudes', 'inverse flags include altitudes'
  atest_has_key, flags, 'energy_flux', 'inverse flags include energy_flux'
  atest_has_key, flags, 'mean_energy', 'inverse flags include mean_energy'
  atest_has_key, flags, 'oxygen_correction_factor', 'inverse flags include oxygen_correction_factor'

  ; the 1.7.0 rename
  atest_false, flags.hasKey('characteristic_energy'), $
    'the pre-1.7.0 characteristic_energy name is gone, replaced by mean_energy'

  n_inverse_keys = n_elements(flags)
  flags = aurorax_atm_inverse_get_output_flags(/set_all_true)
  atest_equal, __atest_flag_sum(flags), n_inverse_keys, '/set_all_true turns every inverse flag on'

  ; the inverse model has a much smaller output set than the forward model
  atest_true, n_inverse_keys lt n_keys, 'the inverse flag set is smaller than the forward one'

  ; -----------------------------------------------------------
  atest_suite, 'ATM model version guards'
  ; -----------------------------------------------------------
  ;
  ; Support for model version 1.0 was removed in 1.9.0. Both entry points
  ; must refuse it, and refuse anything they do not recognise, before they
  ; get anywhere near the network.
  atest_note, 'the next four calls print ATM version errors -- that output is expected'

  flags = aurorax_atm_forward_get_output_flags(/enable_only_height_integrated_rayleighs)
  r = aurorax_atm_forward('2021-11-04T06:00:00', 51.05, -114.07, flags, $
    maxwellian_energy_flux = 10.0, atm_model_version = '1.0')
  atest_null, r, 'the forward model refuses version 1.0'

  flags = aurorax_atm_forward_get_output_flags(/enable_only_height_integrated_rayleighs)
  r = aurorax_atm_forward('2021-11-04T06:00:00', 51.05, -114.07, flags, $
    maxwellian_energy_flux = 10.0, atm_model_version = '3.0')
  atest_null, r, 'the forward model refuses an unknown version'

  flags = aurorax_atm_inverse_get_output_flags(/set_all_true)
  r = aurorax_atm_inverse('2021-11-04T06:00:00', 51.05, -114.07, 100.0, 200.0, 300.0, 400.0, flags, $
    atm_model_version = '1.0')
  atest_null, r, 'the inverse model refuses version 1.0'

  flags = aurorax_atm_inverse_get_output_flags(/set_all_true)
  r = aurorax_atm_inverse('2021-11-04T06:00:00', 51.05, -114.07, 100.0, 200.0, 300.0, 400.0, flags, $
    atm_model_version = '3.0')
  atest_null, r, 'the inverse model refuses an unknown version'
end
