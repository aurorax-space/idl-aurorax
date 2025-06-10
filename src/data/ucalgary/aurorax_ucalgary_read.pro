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

function __reorient_asi_images, dataset_name, data
  compile_opt hidden

  ; NOTE:
  ; flip horizontally --> reverse(data[*,*,0],1) -- subscript index = 1
  ; flip vertically  --> reverse(data[*,*,0],2) -- subscript index = 2

  if (dataset_name eq 'THEMIS_ASI_RAW') then begin
    ; themis - flip vertically
    data = reverse(data, 2)
  endif
  if (dataset_name eq 'REGO_RAW') then begin
    ; rego - flip vertically and horizontally
    data = reverse(data, 1)
    data = reverse(data, 2)
  endif
  if (dataset_name eq 'TREX_BLUE_RAW') then begin
    ; trex blue - flip vertically
    data = reverse(data, 2)
  endif
  if (dataset_name eq 'TREX_NIR_RAW') then begin
    ; trex nir - flip vertically
    data = reverse(data, 2)
  endif
  if (dataset_name eq 'TREX_RGB_RAW_NOMINAL' or dataset_name eq 'TREX_RGB_RAW_BURST') then begin
    ; trex rgb - flip vertically
    data = reverse(data, 3)
  endif

  ; return
  return, data
end

function __reorient_skymaps, dataset_name, skymap
  compile_opt hidden

  ; NOTE:
  ; flip horizontally --> reverse(data[*,*,0],1) -- subscript index = 1
  ; flip vertically  --> reverse(data[*,*,0],2) -- subscript index = 2

  ; flip several things vertically
  skymap.full_elevation = reverse(skymap.full_elevation, 2)
  skymap.full_azimuth = reverse(skymap.full_azimuth, 2)
  skymap.full_map_latitude = reverse(skymap.full_map_latitude, 2)
  skymap.full_map_longitude = reverse(skymap.full_map_longitude, 2)

  if (dataset_name eq 'REGO_SKYMAP_IDLSAV') then begin
    ; flip horizontally too, but just for REGO (since we do this to the raw data too)
    skymap.full_elevation = reverse(skymap.full_elevation, 1)
    skymap.full_azimuth = reverse(skymap.full_azimuth, 1)
    skymap.full_map_latitude = reverse(skymap.full_map_latitude, 1)
    skymap.full_map_longitude = reverse(skymap.full_map_longitude, 1)
  endif

  if (dataset_name eq 'TREX_SPECT_SKYMAP_IDLSAV') then begin
    ; flip single axis mapping variables in spectrograph skymaps as
    ; they get read in a bit differently due to single dimension
    skymap.full_elevation = reverse(skymap.full_elevation, 1)
    skymap.full_map_latitude = reverse(skymap.full_map_latitude, 1)
    skymap.full_map_longitude = reverse(skymap.full_map_longitude, 1)
  endif

  ; return
  return, skymap
end

function __reorient_calibration, dataset_name, cal
  compile_opt hidden

  ; NOTE:
  ; flip horizontally --> reverse(data[*,*,0],1) -- subscript index = 1
  ; flip vertically  --> reverse(data[*,*,0],2) -- subscript index = 2

  if (dataset_name eq 'REGO_CALIBRATION_FLATFIELD_IDLSAV') then begin
    ; flip vertically and horizontally
    cal.flat_field_multiplier = reverse(cal.flat_field_multiplier, 1)
    cal.flat_field_multiplier = reverse(cal.flat_field_multiplier, 2)
  endif
  if (dataset_name eq 'TREX_NIR_CALIBRATION_FLATFIELD_IDLSAV') then begin
    ; flip vertically
    cal.flat_field_multiplier = reverse(cal.flat_field_multiplier, 2)
  endif

  ; return
  return, cal
end

;+
; :Description:
;       Read data files that were downloaded from the UCalgary Open Data Platform.
;
; :Parameters:
;       dataset: in, required, Struct
;         struct for the dataset that is being read in (retrieved from aurorax_list_dataset() function)
;       file_list: in, required, String or Array
;         list of files on the local computer to read in (can also be a single filename string)
;
; :Keywords:
;       start_dt: in, optional, String
;         string giving the start timestamp to read data for (format: 'yyyy-mm-ddTHH:MM:SS')
;       end_dt: in, optional, String
;         string giving the end timestamp to read data for (format: 'yyyy-mm-ddTHH:MM:SS')
;       first_record: in, optional, Boolean
;         only read the first record/frame/image in each file
;       no_metadata: in, optional, Boolean
;         exclude reading of metadata
;       quiet: in, optional, Boolean
;         read data silently, no print messages will be shown
;
; :Returns:
;       Struct
;
; :Examples:
;       download_obj = aurorax_ucalgary_download('THEMIS_ASI_RAW', '2022-01-01T06:00:00', '2022-01-01T06:59:59', site_uid = 'gill')
;       data = aurorax_ucalgary_read(d.dataset, d.filenames)
;       help,data
;
;       data = aurorax_ucalgary_read(d.dataset, d.filenames, start_dt = '2022-01-01T06:13:00', end_dt = '2022-01-01T06:40:00')
;       help, data
;+
function aurorax_ucalgary_read, dataset, file_list, start_dt = start_dt, end_dt = end_dt, first_record = first_record, no_metadata = no_metadata, quiet = quiet
  ; init
  timestamp_list = list()
  metadata_list = list()
  calibrated_data = ptr_new()

  ; set keyword flags
  quiet_flag = 0
  if keyword_set(quiet) then quiet_flag = 1

  ; check if this dataset is supported for reading
  supported = aurorax_ucalgary_is_read_supported(dataset.name)

  ; check that start_dt/end_dt are valid if they are passed
  if keyword_set(start_dt) then begin
    ; ensure string type
    if ~isa(start_dt, /string) then begin
      print, '[aurorax_read] Start timestamp of type ' + typename(start_dt) + ' is invalid, expected string'
      return, !null
    endif else if ~isa(end_dt, /string) then begin
      print, '[aurorax_read] End timestamp of type ' + typename(end_dt) + ' is invalid, expected string'
      return, !null
    endif

    ; ensure string format
    if strlen(start_dt) eq 16 then start_dt += ':00'
    if strlen(end_dt) eq 16 then end_dt += ':00'
    if strlen(start_dt) ne strlen(end_dt) then begin
      print, '[aurorax_read] Start and end timestamp must have the same format'
      print, strlen(start_dt)
      print, strlen(end_dt)
      return, !null
    endif
    if strlen(start_dt) ne 19 or strmid(start_dt, 4, 1) ne '-' or strmid(start_dt, 7, 1) ne '-' or $
      strmid(start_dt, 10, 1) ne 'T' or strmid(start_dt, 13, 1) ne ':' or strmid(start_dt, 16, 1) ne ':' then begin
      print, '[aurorax_read] Start timetsamp must have format "yyyy-mm-ddTHH:MM" or "yyyy-mm-ddTHH:MM:SS", received' + start_dt
      return, !null
    endif
    if strlen(end_dt) ne 19 or strmid(end_dt, 4, 1) ne '-' or strmid(end_dt, 7, 1) ne '-' or $
      strmid(end_dt, 10, 1) ne 'T' or strmid(end_dt, 13, 1) ne ':' or strmid(end_dt, 16, 1) ne ':' then begin
      print, '[aurorax_read] End timetsamp must have format "yyyy-mm-ddTHH:MM" or "yyyy-mm-ddTHH:MM:SS", received' + end_dt
      return, !null
    endif
  endif

  if (supported eq 0) then begin
    print, '[aurorax_read] Dataset ''' + dataset.name + ''' not supported for reading'
    return, !null
  endif

  ; determine read function to use
  imager_readfile_datasets = list( $
    'THEMIS_ASI_RAW', $
    'REGO_RAW', $
    'TREX_NIR_RAW', $
    'TREX_BLUE_RAW', $
    'TREX_RGB_RAW_NOMINAL', $
    'TREX_RGB_RAW_BURST', $
    'TREX_SPECT_RAW', $
    'SMILE_ASI_RAW')
  skymap_readfile_datasets = list( $
    'REGO_SKYMAP_IDLSAV', $
    'THEMIS_ASI_SKYMAP_IDLSAV', $
    'TREX_NIR_SKYMAP_IDLSAV', $
    'TREX_RGB_SKYMAP_IDLSAV', $
    'TREX_BLUE_SKYMAP_IDLSAV', $
    'TREX_SPECT_SKYMAP_IDLSAV', $
    'SMILE_ASI_SKYMAP_IDLSAV')
  calibration_readfile_datasets = list( $
    'REGO_CALIBRATION_RAYLEIGHS_IDLSAV', $
    'REGO_CALIBRATION_FLATFIELD_IDLSAV', $
    'TREX_NIR_CALIBRATION_RAYLEIGHS_IDLSAV', $
    'TREX_NIR_CALIBRATION_FLATFIELD_IDLSAV', $
    'TREX_BLUE_CALIBRATION_RAYLEIGHS_IDLSAV', $
    'TREX_BLUE_CALIBRATION_FLATFIELD_IDLSAV')
  if (isa(imager_readfile_datasets.where(dataset.name)) eq 1) then begin
    ; use imager readfile
    read_function = 'asi_images'
  endif else if (isa(skymap_readfile_datasets.where(dataset.name)) eq 1) then begin
    ; use skymap readfile
    read_function = 'skymap'
  endif else if (isa(calibration_readfile_datasets.where(dataset.name)) eq 1) then begin
    ; use calibration readfile
    read_function = 'calibration'
  endif else if (dataset.name.contains('_GRID_') eq 1) then begin
    ; use grid readfile
    read_function = 'grid'
  endif else if (dataset.name.contains('TREX_SPECT_PROCESSED_') eq 1) then begin
    ; use grid readfile
    read_function = 'trex_spect_processed'
  endif

  ; read the data
  if (read_function eq 'asi_images') then begin
    ; read using ASI readfile
    if (quiet_flag eq 0) then begin
      __aurorax_ucalgary_readfile_asi, file_list, img, meta, start_dt = start_dt, end_dt = end_dt, count = n_frames, first_frame = first_record, no_metadata = no_metadata, /verbose, /show_datarate
    endif else begin
      __aurorax_ucalgary_readfile_asi, file_list, img, meta, start_dt = start_dt, end_dt = end_dt, count = n_frames, first_frame = first_record, no_metadata = no_metadata
    endelse

    ; set the data
    data = img
    data = __reorient_asi_images(dataset.name, data)

    ; set the timestamps
    for i = 0, n_elements(meta) - 1 do begin
      timestamp_list.add, meta[i].exposure_start_string
    endfor

    ; set metadata list
    metadata_list = meta
  endif else if (read_function eq 'skymap') then begin
    if keyword_set(start_dt) then print, '[aurorax_read] Keyword start_dt is not valid for reading skymaps, ignoring.'
    if keyword_set(end_dt) then print, '[aurorax_read] Keyword end_dt is not valid for reading skymaps, ignoring.'
    ; read using skymap readfile
    data = __aurorax_ucalgary_readfile_skymap(file_list, quiet_flag = quiet_flag)
    for i = 0, n_elements(data) - 1 do begin
      data[i] = __reorient_skymaps(dataset.name, data[i])
    endfor
  endif else if (read_function eq 'calibration') then begin
    if keyword_set(start_dt) then print, '[aurorax_read] Keyword start_dt is not valid for reading calibration files, ignoring.'
    if keyword_set(end_dt) then print, '[aurorax_read] Keyword end_dt is not valid for reading calibration files, ignoring.'
    ; read using calibration readfile
    data = __aurorax_ucalgary_readfile_calibration(file_list, quiet_flag = quiet_flag)
    for i = 0, n_elements(data) - 1 do begin
      data[i] = __reorient_calibration(dataset.name, data[i])
    endfor
  endif else if (read_function eq 'grid') then begin
    ; read using grid readfile
    __aurorax_ucalgary_readfile_grid, file_list, data, timestamp_list, metadata_list, start_dt = start_dt, end_dt = end_dt, first_frame = first_record
  endif else if (read_function eq 'trex_spect_processed') then begin
    ; read using trex spectrograph processed readfile
    __aurorax_ucalgary_readfile_trex_spect_processed, file_list, data, timestamp_list, metadata_list, start_dt = start_dt, end_dt = end_dt, first_frame = first_record
  endif

  ; put data into a struct
  return, {data: data, timestamp: timestamp_list, metadata: metadata_list, calibrated_data: calibrated_data, dataset: dataset}
end
