;-------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;-------------------------------------------------------------

function aurorax_keogram_create, images, time_stamp, axis=axis

  if not isa(images, /array) then stop, "(aurorax_keogram_create) Error: 'images' must be an array"

  ; Determine which dimension to slice keogram from
  if not keyword_set(axis) then axis = 0
  if axis ne 0 and axis ne 1 then begin
    print, "(aurorax_keogram_create) Error: Allowed axis values are 0 or 1.
  endif

  ; Get the number of channels of image data
  images_shape = size(images, /dimensions)
  if n_elements(images_shape) eq 2 then begin
    stop, "(aurorax_keogram_create) Error: 'images' must contain multiple frames."
  endif else if n_elements(images_shape) eq 3 then begin
    if images_shape[0] eq 3 then stop, "(aurorax_keogram_create) Error: 'images' must contain multiple frames."
    n_channels = 1
  endif else if n_elements(images_shape) eq 4 then begin
    n_channels = images_shape[0]
  endif else stop, "(aurorax_keogram_create) Error: Unable to determine number of channels based on the supplied images. " + $
    "Make sure you are supplying a [cols,rows,images] or [channels,cols,rows,images] sized array."

  ; Extract the keogram slice, transpose and reshape for proper output shape
  if n_channels eq 1 then begin
    if axis eq 0 then begin
      keo_idx = images_shape[0] / 2
      keo_arr = transpose(reform(images[keo_idx,*,*]))
    endif else begin
      keo_idx = images_shape[1] / 2
      keo_arr = transpose(reform(images[*,keo_idx,*]))
    endelse
  endif else begin
    if axis eq 0 then begin
      keo_idx = images_shape[1] / 2
      keo_arr = reform(images[*,keo_idx,*,*])
      keo_arr = bytscl(transpose(keo_arr, [0,2,1]), min=0, max=255)
    endif else begin
      keo_idx = images_shape[2] / 2
      keo_arr = reform(images[*,*,keo_idx,*])
      keo_arr = bytscl(transpose(keo_arr, [0,2,1]), min=0, max=255)
    endelse
  endelse

  ; Create CCD Y axis
  if n_channels eq 1 then begin
    ccd_y = indgen((size(keo_arr, /dimensions))[1])
  endif else begin
    ccd_y = indgen((size(keo_arr, /dimensions))[2])
  endelse

  ; Return keogram array
  return, {data:keo_arr, ccd_y:ccd_y, slice_idx:keo_idx, timestamp:time_stamp, axis:axis}

end
