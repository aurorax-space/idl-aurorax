function __reorient_asi_images,dataset_name,data
  ; NOTE:
  ; flip horizonally --> reverse(data[*,*,0],1) -- subscript index = 1
  ; flip vertically  --> reverse(data[*,*,0],2) -- subscript index = 2

  if (dataset_name eq 'THEMIS_ASI_RAW') then begin
    ; themis - flip vertically
    data = reverse(data,2)
  endif
  if (dataset_name eq 'REGO_RAW') then begin
    ; rego - flip vertically and horizontally
    data = reverse(data,1)
    data = reverse(data,2)
  endif
  if (dataset_name eq 'TREX_BLUE_RAW') then begin
    ; trex blue - flip vertically
    data = reverse(data,2)
  endif
  if (dataset_name eq 'TREX_NIR_RAW') then begin
    ; trex nir - flip vertically
    data = reverse(data,2)
  endif
  if (dataset_name eq 'TREX_RGB_RAW_NOMINAL' or dataset_name eq 'TREX_RGB_RAW_BURST') then begin
    ; trex rgb - flip vertically
    data = reverse(data,3)
  endif

  ; return
  return,data
end

function __reorient_skymaps,dataset_name,skymap
  ; NOTE:
  ; flip horizonally --> reverse(data[*,*,0],1) -- subscript index = 1
  ; flip vertically  --> reverse(data[*,*,0],2) -- subscript index = 2

  ; flip several things vertically
  skymap.full_elevation = reverse(skymap.full_elevation,2)
  skymap.full_azimuth = reverse(skymap.full_azimuth,2)
  skymap.full_map_latitude = reverse(skymap.full_map_latitude,2)
  skymap.full_map_longitude = reverse(skymap.full_map_longitude,2)

  if (dataset_name eq 'REGO_SKYMAP_IDLSAV') then begin
    ; flip horizontally too, but just for REGO (since we do this to the raw data too)
    skymap.full_elevation = reverse(skymap.full_elevation,1)
    skymap.full_azimuth = reverse(skymap.full_azimuth,1)
    skymap.full_map_latitude = reverse(skymap.full_map_latitude,1)
    skymap.full_map_longitude = reverse(skymap.full_map_longitude,1)
  endif

  ; return
  return,skymap
end

function __reorient_calibration,dataset_name,cal
  ; NOTE:
  ; flip horizonally --> reverse(data[*,*,0],1) -- subscript index = 1
  ; flip vertically  --> reverse(data[*,*,0],2) -- subscript index = 2

  if (dataset_name eq 'REGO_CALIBRATION_FLATFIELD_IDLSAV') then begin
    ; flip vertically and horizontally
    cal.flat_field_multiplier = reverse(cal.flat_field_multiplier,1)
    cal.flat_field_multiplier = reverse(cal.flat_field_multiplier,2)
  endif
  if (dataset_name eq 'TREX_NIR_CALIBRATION_FLATFIELD_IDLSAV') then begin
    ; flip vertically
    cal.flat_field_multiplier = reverse(cal.flat_field_multiplier,2)
  endif

  ; return
  return,cal
end

function aurorax_ucalgary_read,dataset,file_list,first_record=first_record,no_metadata=no_metadata,quiet=quiet
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
    print,"[aurorax_read] Dataset '" + dataset.name + "' not supported for reading"
    return,!NULL
  endif

  ; determine read function to use
  imager_readfile_datasets = list($
    'THEMIS_ASI_RAW',$
    'REGO_RAW',$
    'TREX_NIR_RAW',$
    'TREX_BLUE_RAW',$
    'TREX_RGB_RAW_NOMINAL',$
    'TREX_RGB_RAW_BURST')
  skymap_readfile_datasets = list($
    'REGO_SKYMAP_IDLSAV',$
    'THEMIS_ASI_SKYMAP_IDLSAV',$
    'TREX_NIR_SKYMAP_IDLSAV',$
    'TREX_RGB_SKYMAP_IDLSAV',$
    'TREX_BLUE_SKYMAP_IDLSAV')
  calibration_readfile_datasets = list($
    'REGO_CALIBRATION_RAYLEIGHS_IDLSAV',$
    'REGO_CALIBRATION_FLATFIELD_IDLSAV',$
    'TREX_NIR_CALIBRATION_RAYLEIGHS_IDLSAV',$
    'TREX_NIR_CALIBRATION_FLATFIELD_IDLSAV',$
    'TREX_BLUE_CALIBRATION_RAYLEIGHS_IDLSAV',$
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
  endif

  ; read the data
  if (read_function eq 'asi_images') then begin
    ; read using ASI readfile
    if (quiet_flag eq 0) then begin
      aurorax_ucalgary_readfile_asi,file_list,img,meta,count=n_frames,first_frame=first_record,no_metadata=no_metadata,/verbose,/show_datarate
    endif else begin
      aurorax_ucalgary_readfile_asi,file_list,img,meta,count=n_frames,first_frame=first_record,no_metadata=no_metadata
    endelse

    ; set the data
    data = img
    data = __reorient_asi_images(dataset.name, data)

    ; set the timestamps
    for i=0,n_elements(meta)-1 do begin
      timestamp_list.Add,meta[i].exposure_start_string
    endfor

    ; set metadata list
    metadata_list = meta
  endif else if (read_function eq 'skymap') then begin
    ; read using skymap readfile
    data = aurorax_ucalgary_readfile_skymap(file_list,quiet_flag=quiet_flag)
    for i=0,n_elements(data)-1 do begin
      data[i] = __reorient_skymaps(dataset.name,data[0])
    endfor
  endif else if (read_function eq 'calibration') then begin
    ; read using calibration readfile
    data = aurorax_ucalgary_readfile_calibration(file_list,quiet_flag=quiet_flag)
    for i=0,n_elements(data)-1 do begin
      data[i] = __reorient_calibration(dataset.name,data[0])
    endfor
  endif

  ; put data into a struct
  return,{data: data, timestamp: timestamp_list, metadata: metadata_list, calibrated_data: calibrated_data, dataset: dataset}
end