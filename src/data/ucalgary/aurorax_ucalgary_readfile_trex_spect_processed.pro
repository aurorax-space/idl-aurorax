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

pro __aurorax_ucalgary_readfile_trex_spect_processed, file_path, data, timestamp_list, meta, first_frame = first_frame, verbose = verbose
  compile_opt idl2, hidden

  ; set verbose
  if not isa(verbose) then verbose = 1

  ; setting up master lists to hold data for multi-file reading
  master_timestamp = []
  master_file_meta = []
  master_wavelength = []

  ; convert scalar filename to length 1 array so we can 'iterate' regardless
  if isa(file_path, /scalar) then file_path = [file_path]

  foreach f, file_path do begin
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
    if (n_elements(master_wavelength) eq 0) then begin
      wavelength_dataset_id = h5d_open(data_group_id, 'wavelength')
      master_wavelength = h5d_read(wavelength_dataset_id)
    endif

    ; transposing the spectra data for proper IDL dimensionality
    spectra = reverse(transpose(spectra, [1, 2, 0]), 2)

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
    file_meta = file_meta_hash.toStruct()
    master_file_meta = [master_file_meta, file_meta]

    ; if first_frame_only keyword is set, slice all objects accordingly so that
    ; only data and metadata corresponding to the first frame is returned
    if keyword_set(first_frame) then begin
      spectra = spectra[*, *, 0]
      timestamp = timestamp[0]
      file_meta = file_meta[0]
    endif

    ; append to spectra array
    master_shape = size(master_spectra, /dimensions)
    spectra_shape = size(spectra, /dimensions)
    new_nframes = master_shape[-1] + spectra_shape[-1]
    if isa(master_spectra) then begin
      master_spectra = reform([reform(master_spectra, master_spectra.length), $
        reform(spectra, spectra.length)], [master_shape[0 : n_elements(master_shape) - 2], new_nframes])
    endif else begin
      master_spectra = spectra
    endelse

    ; append to timestamp
    master_timestamp = [master_timestamp, timestamp]

    ; close file
    h5_close
  endforeach

  ; creating the meta struct that is to be returned
  meta = {timestamp: master_timestamp, wavelength: master_wavelength, file_meta: master_file_meta}
  data = {spectra: master_spectra}
end
