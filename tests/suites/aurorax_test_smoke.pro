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
; A compile smoke test for the library's public surface.
;
; IDL only reports a syntax error when it tries to compile the routine, so a
; broken routine in a rarely used file can sit undetected until a user calls
; it. The loader has already compiled everything by the time this runs, so
; checking that each public routine is actually resolvable turns any such
; breakage into a test failure.

;+
; Assert that a routine compiled successfully and is callable.
;-
pro __atest_routine_exists, name, is_function
  compile_opt idl2

  upper_name = strupcase(name)
  if (is_function) then begin
    compiled = routine_info(/functions)
    label = 'function'
  endif else begin
    compiled = routine_info()
    label = 'procedure'
  endelse

  found = (where(compiled eq upper_name))[0] ne -1
  atest_ok, found, label + ' ' + name + ' compiled', $
    detail = 'not resolvable -- the file it lives in probably failed to compile'
end

pro aurorax_test_smoke
  compile_opt idl2

  ; -----------------------------------------------------------
  atest_suite, 'smoke -- search engine functions'
  ; -----------------------------------------------------------
  search_functions = [ $
    'aurorax_conjunction_search', $
    'aurorax_conjunction_describe', $
    'aurorax_create_advanced_distances_hash', $
    'aurorax_create_criteria_block', $
    'aurorax_create_metadata_filter', $
    'aurorax_create_metadata_filter_expression', $
    'aurorax_create_response_format_template', $
    'aurorax_ephemeris_search', $
    'aurorax_ephemeris_describe', $
    'aurorax_data_product_search', $
    'aurorax_data_product_describe', $
    'aurorax_ephemeris_availability', $
    'aurorax_data_products_availability', $
    'aurorax_list_sources']
  for i = 0, n_elements(search_functions) - 1 do __atest_routine_exists, search_functions[i], 1

  ; -----------------------------------------------------------
  atest_suite, 'smoke -- data access functions'
  ; -----------------------------------------------------------
  data_functions = [ $
    'aurorax_list_datasets', $
    'aurorax_get_dataset', $
    'aurorax_list_observatories', $
    'aurorax_ucalgary_get_urls', $
    'aurorax_ucalgary_download', $
    'aurorax_ucalgary_download_best_skymap', $
    'aurorax_ucalgary_download_best_calibration', $
    'aurorax_ucalgary_read', $
    'aurorax_ucalgary_is_read_supported']
  for i = 0, n_elements(data_functions) - 1 do __atest_routine_exists, data_functions[i], 1

  ; -----------------------------------------------------------
  atest_suite, 'smoke -- model functions'
  ; -----------------------------------------------------------
  model_functions = [ $
    'aurorax_atm_forward', $
    'aurorax_atm_inverse', $
    'aurorax_atm_forward_get_output_flags', $
    'aurorax_atm_inverse_get_output_flags']
  for i = 0, n_elements(model_functions) - 1 do __atest_routine_exists, model_functions[i], 1

  ; -----------------------------------------------------------
  atest_suite, 'smoke -- analysis tool functions'
  ; -----------------------------------------------------------
  tool_functions = [ $
    'aurorax_keogram_create', $
    'aurorax_keogram_create_custom', $
    'aurorax_keogram_add_axis', $
    'aurorax_keogram_inject_nans', $
    'aurorax_keogram_plot', $
    'aurorax_montage_create', $
    'aurorax_mosaic_prep_images', $
    'aurorax_mosaic_prep_skymap', $
    'aurorax_bounding_box_extract_metric', $
    'aurorax_ccd_contour', $
    'aurorax_calibrate_rego', $
    'aurorax_calibrate_trex_nir', $
    'aurorax_get_decomposed_color', $
    'aurorax_prep_grid_image', $
    'aurorax_spectra_get_intensity', $
    'aurorax_spectra_plot']
  for i = 0, n_elements(tool_functions) - 1 do __atest_routine_exists, tool_functions[i], 1

  ; -----------------------------------------------------------
  atest_suite, 'smoke -- top level functions'
  ; -----------------------------------------------------------
  top_functions = ['aurorax_check_version', 'aurorax_get_proxy']
  for i = 0, n_elements(top_functions) - 1 do __atest_routine_exists, top_functions[i], 1

  ; -----------------------------------------------------------
  atest_suite, 'smoke -- procedures'
  ; -----------------------------------------------------------
  procedures = [ $
    'aurorax_set_proxy', $
    'aurorax_clear_proxy', $
    'aurorax_mosaic_plot', $
    'aurorax_mosaic_oplot', $
    'aurorax_fov_oplot', $
    'aurorax_movie', $
    'aurorax_open_conjunctions_in_swarmaurora', $
    'aurorax_open_conjunctions_in_aurorax', $
    'aurorax_save_swarmaurora_custom_import_file']
  for i = 0, n_elements(procedures) - 1 do __atest_routine_exists, procedures[i], 0

  ; -----------------------------------------------------------
  atest_suite, 'smoke -- private helpers the tests depend on'
  ; -----------------------------------------------------------
  ;
  ; These are internal, but several suites call them directly. If one is
  ; renamed the tests that use it would otherwise fail with a confusing
  ; "undefined procedure" error rather than something that points here.
  helpers = [ $
    '__aurorax_version', $
    '__aurorax_datetime_parser', $
    '__aurorax_humanize_bytes', $
    '__aurorax_time2string', $
    '__aurorax_extract_request_id_from_response_headers', $
    '__aurorax_conjunctions_create_post_str', $
    '__aurorax_ephemeris_create_post_str', $
    '__aurorax_derive_advanced_distances']
  for i = 0, n_elements(helpers) - 1 do __atest_routine_exists, helpers[i], 1
end
