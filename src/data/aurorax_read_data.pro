function aurorax_read_data,dataset,file_list,first_record=first_record,no_metadata=no_metadata,quiet=quiet
  ; set keyword flags
  quiet_flag = 0
  if keyword_set(quiet) then quiet_flag = 1

  ; read the data
  if (quiet_flag eq 0) then begin
    aurorax_asi_readfile,file_list,img,meta,count=n_frames,first_frame=first_record,no_metadata=no_metadata,/verbose,/show_datarate
  endif else begin
    aurorax_asi_readfile,file_list,img,meta,count=n_frames,first_frame=first_record,no_metadata=no_metadata
  endelse

  ; set the timestamps
  timestamp_list = list()
  timestamp_cdf_list = list()
  for i=0,n_elements(meta)-1 do begin
    timestamp_list.Add,meta[i].exposure_start_string
    timestamp_cdf_list.Add,meta[i].exposure_start_cdf
  endfor

  ; put data into a struct
  return,{data: img, timestamp: timestamp_list, timestamp_cdf: timestamp_cdf_list, metadata: meta, dataset: dataset}
end