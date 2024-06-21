function aurorax_ucalgary_is_read_supported,dataset_name
  supported_datasets = list($
    'THEMIS_ASI_RAW',$
    'REGO_RAW',$
    'TREX_NIR_RAW',$
    'TREX_BLUE_RAW',$
    'TREX_RGB_RAW_NOMINAL',$
    'TREX_RGB_RAW_BURST',$
    'REGO_SKYMAP_IDLSAV',$
    'THEMIS_ASI_SKYMAP_IDLSAV',$
    'TREX_NIR_SKYMAP_IDLSAV',$
    'TREX_RGB_SKYMAP_IDLSAV',$
    'TREX_BLUE_SKYMAP_IDLSAV',$
    'REGO_CALIBRATION_RAYLEIGHS_IDLSAV',$
    'REGO_CALIBRATION_FLATFIELD_IDLSAV',$
    'TREX_NIR_CALIBRATION_RAYLEIGHS_IDLSAV',$
    'TREX_NIR_CALIBRATION_FLATFIELD_IDLSAV',$
    'TREX_BLUE_CALIBRATION_RAYLEIGHS_IDLSAV',$
    'TREX_BLUE_CALIBRATION_FLATFIELD_IDLSAV')

  ; check
  supported = supported_datasets.where(dataset_name)
  if (isa(supported) eq 1) then begin
    ; found match
    return,1
  endif else begin
    ; did not find match, null was returned from the where call
    return,0
  endelse
end