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
  compile_opt idl2, hidden

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
  compile_opt idl2, hidden

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

  ; return
  return, skymap
end

function __reorient_calibration, dataset_name, cal
  compile_opt idl2, hidden

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
;       FIRST_RECORD: in, optional, Boolean
;         only read the first record/frame/image in each file
;       NO_METADATA: in, optional, Boolean
;         exclude reading of metadata
;       QUIET: in, optional, Boolean
;         read data silently, no print messages will be shown
;
; :Returns:
;       Struct
;
; :Examples:
;       download_obj = aurorax_ucalgary_download('THEMIS_ASI_RAW','2022-01-01T06:00:00','2022-01-01T06:59:59',site_uid='gill')
;       data = aurorax_ucalgary_read(d.dataset,f)
;       help,data
;+
function aurorax_ucalgary_read, dataset, file_list, first_record = first_record, no_metadata = no_metadata, quiet = quiet
  compile_opt idl2

  ; init
  timestamp_list = list()
  metadata_list = list()
  calibrated_data = ptr_new()

  ; set keyword flags
  quiet_flag = 0
  if keyword_set(quiet) then quiet_flag = 1

  ; check if this dataset is supported for reading
  supported = aurorax_ucalgary_is_read_supported(dataset.name)

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
    'TREX_SPECT_RAW')
  skymap_readfile_datasets = list( $
    'REGO_SKYMAP_IDLSAV', $
    'THEMIS_ASI_SKYMAP_IDLSAV', $
    'TREX_NIR_SKYMAP_IDLSAV', $
    'TREX_RGB_SKYMAP_IDLSAV', $
    'TREX_BLUE_SKYMAP_IDLSAV')
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
      __aurorax_ucalgary_readfile_asi, file_list, img, meta, count = n_frames, first_frame = first_record, no_metadata = no_metadata, /verbose, /show_datarate
    endif else begin
      __aurorax_ucalgary_readfile_asi, file_list, img, meta, count = n_frames, first_frame = first_record, no_metadata = no_metadata
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
    ; read using skymap readfile
    data = __aurorax_ucalgary_readfile_skymap(file_list, quiet_flag = quiet_flag)
    for i = 0, n_elements(data) - 1 do begin
      data[i] = __reorient_skymaps(dataset.name, data[i])
    endfor
  endif else if (read_function eq 'calibration') then begin
    ; read using calibration readfile
    data = __aurorax_ucalgary_readfile_calibration(file_list, quiet_flag = quiet_flag)
    for i = 0, n_elements(data) - 1 do begin
      data[i] = __reorient_calibration(dataset.name, data[i])
    endfor
  endif else if (read_function eq 'grid') then begin
    ; read using grid readfile
    __aurorax_ucalgary_readfile_grid, file_list, data, timestamp_list, metadata_list, first_frame = first_record
  endif else if (read_function eq 'trex_spect_processed') then begin
    ; read using trex spectrograph processed readfile
    __aurorax_ucalgary_readfile_trex_spect_processed, file_list, data, timestamp_list, metadata_list, first_frame = first_record
  endif

  ; put data into a struct
  return, {data: data, timestamp: timestamp_list, metadata: metadata_list, calibrated_data: calibrated_data, dataset: dataset}
end
