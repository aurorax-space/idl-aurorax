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

pro __aurorax_ucalgary_readfile_grid, $
  grid_file_path, $
  data, $
  timestamp_list, $
  meta, $
  first_frame = first_frame, $
  verbose = verbose
  compile_opt hidden

  if not isa(verbose) then verbose = 1

  ; Setting up master lists to hold data for multi-file reading
  master_timestamp = []
  master_file_meta = []
  master_frame_meta = []

  ; Convert scalar filename to length 1 array so we can 'iterate' regardless
  if isa(grid_file_path, /scalar) then grid_file_path = [grid_file_path]

  foreach f, grid_file_path do begin
    if (verbose gt 0) then print, '[aurorax_read] Reading file: ' + f

    ; Reading the grid data into an
    ; array object to be returned.
    file_id = h5f_open(f)

    data_group_id = h5g_open(file_id, 'data')
    grid_dataset_id = h5d_open(data_group_id, 'grid')
    source_info_group_id = h5g_open(data_group_id, 'source_info')
    confidence_dataset_id = h5d_open(source_info_group_id, 'confidence')
    grid = h5d_read(grid_dataset_id)
    confidence = h5d_read(confidence_dataset_id)

    ; Transposing the grids for proper IDL dimensionality
    if size(grid, /n_dimensions) eq 3 then begin
      grid = reverse(transpose(grid, [1, 2, 0]), 2)
      confidence = reverse(transpose(confidence, [1, 2, 0]), 2)
    endif else if size(grid, /n_dimensions) eq 4 then begin
      grid = reverse(transpose(grid, [1, 2, 3, 0]), 3)
      confidence = reverse(transpose(confidence, [1, 2, 0]), 2)
    endif

    ; The returned 'meta' variable will be an IDL structure that contains the
    ; file level metadata, the frame level metadata, as well as the 'timestamp'
    ; array. So we read each of those into seperate objects, and then create
    ; the struct from there

    ; Reading in the timestamp to an array object to be returned
    timestamp_dataset_id = h5d_open(data_group_id, 'timestamp')
    timestamp = h5d_read(timestamp_dataset_id)

    ; Reading in the file level metadata into a hash and then converting to IDL struct
    meta_group_id = h5g_open(file_id, 'metadata')
    file_meta_dataset_id = h5d_open(meta_group_id, 'file')
    n_file_meta_attributes = h5a_get_num_attrs(file_meta_dataset_id)

    ; Iterating through each attribute and adding to hash, then converting to struct
    file_meta_hash = hash()
    for i = 0, (n_file_meta_attributes - 1) do begin
      attribute_id = h5a_open_idx(file_meta_dataset_id, i)
      attribute_name = h5a_get_name(attribute_id)
      attribute = h5a_read(attribute_id)
      file_meta_hash[attribute_name] = attribute
    endfor

    file_meta = file_meta_hash.toStruct()

    ; Reading in the frame level metadata into a list, where each list element is a meta
    ; structure belonging to the frame of that element's list index
    frame_meta_group_id = h5g_open(meta_group_id, 'frame')
    n_frame_meta_datasets = h5g_get_nmembers(meta_group_id, 'frame')

    ; Iterating through each frame dataset in the frame meta group
    for i = 0, (n_frame_meta_datasets - 1) do begin
      frame_meta_dataset_id = h5d_open(frame_meta_group_id, 'frame' + strcompress(string(i), /remove_all))
      n_frame_meta_attributes = h5a_get_num_attrs(frame_meta_dataset_id)

      ; Iterating through each attribute for the current iteration's dataset and adding to hash
      frame_meta_hash = hash()
      for j = 0, (n_frame_meta_attributes - 1) do begin
        attribute_id = h5a_open_idx(frame_meta_dataset_id, j)
        attribute_name = h5a_get_name(attribute_id)
        attribute = h5a_read(attribute_id)
        frame_meta_hash[attribute_name] = attribute
      endfor

      ; Converting hash to struct and then appending to frame meta list
      frame_meta_struct = frame_meta_hash.toStruct()

      master_frame_meta = [master_frame_meta, frame_meta_struct]
      master_file_meta = [master_file_meta, file_meta]
    endfor

    ; If first_frame_only keyword is set, slice all objects accordingly so that
    ; only data and metadata corresponding to the first frame is returned
    if keyword_set(first_frame) then begin
      if size(grid, /n_dimensions) eq 3 then begin
        grid = grid[*, *, 0]
      endif else if size(grid, /n_dimensions) eq 4 then begin
        grid = grid[*, *, *, 0]
      endif
      confidence = confidence[*, *, 0]
      timestamp = timestamp[0]
      frame_meta = frame_meta[0]
      file_meta = file_meta[0]
    endif

    ; Append to grid array
    master_shape = size(master_grid, /dimensions)
    grid_shape = size(grid, /dimensions)
    new_nframes = master_shape[-1] + grid_shape[-1]
    if isa(master_grid) then begin
      master_grid = reform([reform(master_grid, master_grid.length), $
        reform(grid, grid.length)], [master_shape[0 : n_elements(master_shape) - 2], new_nframes])
    endif else begin
      master_grid = grid
    endelse

    ; Append to confidence array
    master_shape = size(master_confidence, /dimensions)
    confidence_shape = size(confidence, /dimensions)
    new_nframes = master_shape[-1] + confidence_shape[-1]
    if isa(master_confidence) then begin
      master_confidence = reform([reform(master_confidence, master_confidence.length), $
        reform(confidence, confidence.length)], [master_shape[0 : n_elements(master_shape) - 2], new_nframes])
    endif else begin
      master_confidence = confidence
    endelse

    ; Append to timestamp
    master_timestamp = [master_timestamp, timestamp]

    h5_close
  endforeach

  ; Creating the meta struct that is to be returned
  meta = {timestamp: master_timestamp, file_meta: master_file_meta, frame_meta: master_frame_meta}
  data = {grid: master_grid, confidence: master_confidence}
end
