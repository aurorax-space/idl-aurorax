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

; init
print, '[idl-aurorax] Compiling routines'

; set paths for AACGM data files
; 
; NOTE: IDL-AuroraX expects all AACGM_v2 files to be located within !packages_path by default.
;       If AACGM_v2 code / text files are not located in '*\.idl\idl\packages\idl_aurorax\libs\aacgm', 
;       alter the below filepath to point to a different location by default.
igrf_coeffs_path = !package_path + path_sep() + 'idl_aurorax' + path_sep() + $
  'libs' + path_sep() + 'aacgm' + path_sep() + 'magmodel_1590-2025.txt'
aacgm_v2_dat_prefix_path = !package_path + path_sep() + 'idl_aurorax' + path_sep() + $
  'libs' + path_sep() + 'aacgm' + path_sep() + 'coeffs' + path_sep() + 'aacgm_coeffs-14-'
;igrf_coeffs_path = 'C:\Users\darrenc\Documents\GitHub\idl-aurorax\libs\aacgm\magmodel_1590-2025.txt'
;aacgm_v2_dat_prefix_path = 'C:\Users\darrenc\Documents\Github\idl-aurorax\libs\aacgm\coeffs\aacgm_coeffs-14-'

; check paths for AACGM
igrf_coeff_exists = file_test(igrf_coeffs_path)
!null = file_search(aacgm_v2_dat_prefix_path+'*', count=aacgm_v2_dat_exists)
if ((igrf_coeff_exists eq 0) or (aacgm_v2_dat_exists eq 0)) then aacgm_found = 0
print,aacgm_found
if ((igrf_coeff_exists ne 0) and (aacgm_v2_dat_exists ne 0)) then aacgm_found = 1
print,aacgm_found

; initialize AACGM
setenv, 'AACGM_v2_DAT_PREFIX=' + igrf_coeffs_path
setenv, 'IGRF_COEFFS=' + aacgm_v2_dat_prefix_path
.run genmag
.run igrflib_v2
.run aacgmlib_v2
.run aacgm_v2
.run time
.run astalg
.run mlt_v2

; top level
.run aurorax_version
.run aurorax_proxy

; helpers
;
; NOTE: these are here since they need to be compiled before some of 
; the following routines
.run aurorax_requests

; data
.run aurorax_list_datasets
.run aurorax_get_dataset
.run aurorax_list_observatories
.run aurorax_ucalgary_get_urls
.run aurorax_ucalgary_download
.run aurorax_ucalgary_download_best_skymap
.run aurorax_ucalgary_download_best_calibration
.run aurorax_ucalgary_readfile_asi
.run aurorax_ucalgary_readfile_skymap
.run aurorax_ucalgary_readfile_calibration
.run aurorax_ucalgary_readfile_grid
.run aurorax_ucalgary_readfile_trex_spect_processed
.run aurorax_ucalgary_read
.run aurorax_ucalgary_is_read_supported

; search
.run aurorax_search_helpers
.run aurorax_calibrate_helpers
.run aurorax_metadata_filters
.run aurorax_availability
.run aurorax_conjunctions
.run aurorax_data_products
.run aurorax_ephemeris
.run aurorax_sources
.run aurorax_open_externally

; models
.run aurorax_atm_forward_get_output_flags
.run aurorax_atm_forward
.run aurorax_atm_inverse_get_output_flags
.run aurorax_atm_inverse

; tools
.run aurorax_bounding_box_extract_metric
.run aurorax_keogram_create_custom
.run aurorax_ccd_contour
.run aurorax_calibrate_rego
.run aurorax_calibrate_trex_nir
.run aurorax_keogram_add_axis
.run aurorax_keogram_create
.run aurorax_keogram_plot
.run aurorax_montage_create
.run aurorax_mosaic_plot
.run aurorax_mosaic_oplot
.run aurorax_mosaic_prep_images
.run aurorax_mosaic_prep_skymap
.run aurorax_fov_oplot
.run aurorax_get_decomposed_color
.run aurorax_movie

; check if there's a new version available
print, '[idl-aurorax] Checking for new version ...'
version_info = aurorax_check_version(/init_mode)
version_info = hash(version_info, /lowercase)
if (version_info['new_version_available'] eq 1) then print, '[idl-aurorax] ' + version_info['message'].replace('[aurorax_check_version] ', '')

; finish
print, '[idl-aurorax] Initialization complete'

; Check if the AACGM files necessary for environment variable to work were found.
; If they, weren't, print a message to notify the user
if aacgm_found eq 0 then print, '[idl-aurorax] Warning: could not initialize AACGM_v2 library. IDL-AuroraX expects the AACGM coefficient and ' + $
  'magmodel_1590-2025.txt files to be saved at idl_aurorax' + path_sep() + 'libs' + path_sep() + 'aacgm' + path_sep() + '. If these files are saved ' + $
  'elsewhere, you can (A) alter the aurorax_startup.pro file lines 25-28 to the correct paths (RECOMMENDED) or (b) manually set the environment variables ' + $
  'for AACGM every time you run @aurorax_startup, using the commands: `IDL> setenv, "AACGM_v2_DAT_PREFIX=...magmodel_1590-2025.txt"` and ' + $
  '`IDL> setenv, "IGRF_COEFFS=...coeffs' + path_sep() + 'aacgm_coeffs-14-"`.'
