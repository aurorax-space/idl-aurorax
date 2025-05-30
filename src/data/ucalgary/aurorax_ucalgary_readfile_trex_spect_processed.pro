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

pro __aurorax_ucalgary_readfile_trex_spect_processed, $
  filename, $
  data, $
  timestamp_list, $
  meta, $
  start_dt = start_dt, $
  end_dt = end_dt, $
  first_frame = first_frame, $
  verbose = verbose
  compile_opt hidden

  ; set verbose
  if not isa(verbose) then verbose = 1
  
  ; Convert scalar filename to length 1 array so we can 'iterate' regardless
  if isa(filename, /scalar) then filename = [filename]

  ; If start_dt or end_dt were passed, we need to cut down the filenames accordingly
  if keyword_set(start_dt) or keyword_set(end_dt) then begin

    if keyword_set(start_dt) then begin
      start_yy = strmid(start_dt,0,4)
      start_mm = strmid(start_dt,5,2)
      start_dd = strmid(start_dt,8,2)
      start_hr = strmid(start_dt,11,2)
    endif
    if keyword_set(end_dt) then begin
      end_yy = strmid(end_dt,0,4)
      end_mm = strmid(end_dt,5,2)
      end_dd = strmid(end_dt,8,2)
      end_hr = strmid(end_dt,11,2)
    endif

    hr_only = []
    foreach f, filename do begin
      if n_elements(strsplit(f, start_yy+start_mm+start_dd+'_', /extract, /regex)) eq 1 then begin
        hr_only = [hr_only, "nan"]
      endif else begin
        hr_only = [hr_only, strmid((strsplit(f, start_yy+start_mm+start_dd+'_', /extract, /regex))[-1], 0, 2)]
      endelse
    endforeach

    start_dt_idx = where(hr_only eq start_hr, /null)
    end_dt_idx = where(hr_only eq end_hr, /null)
    
    
    ; Check that the start/end time range actually corresponds to the files passed in
    if start_dt_idx eq !null then begin
      print, '[aurorax_read] Error - start_dt does not correspond to any of the input filenames'
      return
    endif else if end_dt_idx eq !null then begin
      print, '[aurorax_read] Error - end_dt does not correspond to any of the input filenames'
      return
    endif

    ; if everything worked properly we can now slice out the filenames we actually want to read
    filename = filename[start_dt_idx:end_dt_idx]

  end
  filename = filename.toarray()

  n_files = n_elements(filename)
  if (n_files gt 1) then filename = filename[sort(filename)]
  
  ; setting up master lists to hold data for multi-file reading
  master_timestamp = []
  master_file_meta = []
  frames_read_counter = 0ul

  foreach f, filename, file_num do begin

    ; init
    if (verbose gt 0) then print, '[aurorax_read] Reading file: ' + f

    ; read spectra data
    file_id = h5f_open(f)
    data_group_id = h5g_open(file_id, 'data')
    spectra_dataset_id = h5d_open(data_group_id, 'spectra')
    spectra = h5d_read(spectra_dataset_id)

    ; read wavelength data
    ;
    ; NOTE: only read it in if we don't already have it (since it doesn't
    ; change from one file to the next)
    if ~ isa(wavelength) then begin
      wavelength_dataset_id = h5d_open(data_group_id, 'wavelength')
      wavelength = h5d_read(wavelength_dataset_id)
    endif

    ; transposing the spectra data for proper IDL dimensionality
    spectra = transpose(spectra, [1, 2, 0])

    ; the returned 'meta' variable will be an IDL structure that contains the
    ; file level metadata, the wavelength data, as well as the 'timestamp' and
    ; array. So we read each of those into seperate objects, and then create
    ; the struct from there

    ; reading in the timestamp to an array object to be returned
    timestamp_dataset_id = h5d_open(data_group_id, 'timestamp')
    timestamp = h5d_read(timestamp_dataset_id)

    ; reading in the file level metadata into a hash and then converting to IDL struct
    meta_group_id = h5g_open(file_id, 'metadata')
    file_meta_dataset_id = h5d_open(meta_group_id, 'file')
    n_file_meta_attributes = h5a_get_num_attrs(file_meta_dataset_id)

    ; iterating through each attribute and adding to hash, then converting to struct
    ; and add to the master file metadata list
    file_meta_hash = hash()
    for i = 0, (n_file_meta_attributes - 1) do begin
      attribute_id = h5a_open_idx(file_meta_dataset_id, i)
      attribute_name = h5a_get_name(attribute_id)
      attribute = h5a_read(attribute_id)
      file_meta_hash[attribute_name] = attribute
    endfor
    
    if ~ isa(file_meta) then file_meta = file_meta_hash.toStruct()

    ; append to spectra array
    master_shape = size(master_spectra, /dimensions)
    spectra_dims = size(spectra, /dimensions)    
    if file_num eq 0 then begin
      
      ; allocate memory for spectra data assuming 240 frames per file (will be trimmed at the end)
      predicted_n_frames = 240 * n_files
      master_spectra = make_array([spectra_dims[0:n_elements(spectra_dims)-2], predicted_n_frames], type=size(spectra, /type))
      
      ; insert the first file's data into the newly allocated arrays
      n_frames = (size(spectra, /dimensions))[-1]
      if keyword_set(first_frame) then begin
        n_frames = 1
        master_spectra[*,*,frames_read_counter:frames_read_counter] = spectra[*,*,0]
      endif else begin
        master_spectra[*,*,frames_read_counter:frames_read_counter+n_frames-1] = spectra
      endelse
      
    endif else begin
      
      if keyword_set(first_frame) then begin
        ; insert this file's data into the arrays
        n_frames = 1
        master_spectra[*,*,frames_read_counter:frames_read_counter+n_frames-1] = spectra[*,*,0]
      endif else begin
        ; insert this file's data into the arrays
        n_frames = (size(spectra, /dimensions))[-1]
        master_spectra[*,*,frames_read_counter:frames_read_counter+n_frames-1] = spectra
      endelse

    endelse
      
    ; update the number of frames we've read in
    frames_read_counter += n_frames
    
    if keyword_set(first_frame) then timestamp = timestamp[0]
    
    ; append to timestamp
    master_timestamp = [master_timestamp, timestamp]

    ; close file
    h5_close
  endforeach
  
  ; Create metadata structure to return
  meta = {timestamp: master_timestamp, wavelength: wavelength, file_meta: file_meta}
  
  ; Removing additional data frames if less frames read in than expected
  master_spectra_dims = size(master_spectra, /dimensions)
  if n_elements(master_spectra_dims) eq 3 then master_spectra = master_spectra[*,*,0:frames_read_counter-1]
  
  ; Create data structure to return
  data = {spectra: master_spectra}
  
end
