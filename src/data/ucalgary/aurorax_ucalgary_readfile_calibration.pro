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

function __aurorax_ucalgary_readfile_calibration, file_list, quiet_flag = quiet_flag
  compile_opt hidden

  ; init
  cals = list()

  ; read each file
  for i = 0, n_elements(file_list) - 1 do begin
    ; print
    if (quiet_flag eq 0) then begin
      print, '[aurorax_read] Reading file: ' + file_list[i]
    endif

    ; restore file
    restore, file_list[i]

    ; extract the device UID from the filename
    device_uid = ((file_basename(file_list[i])).split('_'))[2]

    ; extract the version from the filename
    version_str = (((file_basename(file_list[i])).split('_'))[-1].split('\.'))[0]

    ; set generation info
    if (isa(author) eq 0) then author = ''
    if (isa(input_data_dir) eq 0) then input_data_dir = ''
    if (isa(skymap_filename) eq 0) then skymap_filename = ''
    generation_info_struct = {author: author, input_data_dir: input_data_dir, skymap_filename: skymap_filename}

    ; set rayleighs value
    rayleighs_value = ptr_new()
    if ((file_list[i].tolower()).indexof('rayleighs') ne -1) then begin
      rayleighs_value = scope_varfetch('rper_dnpersecond_' + device_uid)
    endif

    ; set flatfield multiplier value
    flatfield_value = ptr_new()
    if ((file_list[i].tolower()).indexof('flat') ne -1) then begin
      flatfield_value = scope_varfetch('flat_field_multiplier_' + device_uid)
    endif

    ; set object
    ;
    ; NOTE: we need to not name this 'skymap' because otherwise we'll
    ; collide with the just-restored 'skymap' variable.
    cal_obj = { $
      filename: file_list[i], $
      device_uid: device_uid, $
      version: version_str, $
      generation_info: generation_info_struct, $
      rayleighs_perdn_persecond: rayleighs_value, $
      flat_field_multiplier: flatfield_value}

    ; append to list
    cals.add, cal_obj
  endfor

  ; return
  return, cals
end
