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

    ; set the timestamps
    for i=0,n_elements(meta)-1 do begin
      timestamp_list.Add,meta[i].exposure_start_string
    endfor

    ; set metadata list
    metadata_list = meta
  endif else if (read_function eq 'skymap') then begin
    ; read using skymap readfile
    data = aurorax_ucalgary_readfile_skymap(file_list,quiet_flag=quiet_flag)
  endif else if (read_function eq 'calibration') then begin
    ; read using calibration readfile
    data = aurorax_ucalgary_readfile_calibration(file_list,quiet_flag=quiet_flag)
  endif

  ; put data into a struct
  return,{data: data, timestamp: timestamp_list, metadata: metadata_list, calibrated_data: calibrated_data, dataset: dataset}
end