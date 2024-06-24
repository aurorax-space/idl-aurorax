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

;-------------------------------------------------------------
;+
; NAME:
;       AURORAX_MONTAGE_CREATE
;
; PURPOSE:
;       Create and display a montage.
;
; EXPLANATION:
;       Create a montage from a set of images, and display
;       it, accompanied by timestamps.
;
; CALLING SEQUENCE:
;       aurorax_montage_create, images, time_stamp, n_cols, n_rows
;
; PARAMETERS:
;       images                  array of images to create the montage for 
;       timestamps              timestamps corresponding to each frame of images
;       n_cols                  integer specifying the number of columns in the montage
;       n_rows                  integer specifying the number of rows in the montage
;       colortable              integer specifying the IDL colortable to use, optional (default is 0)
;       timestamps_fontsize     font size for the timestamp labals, optional
;       frame_step              interval to add frames from images to the montage, optional (default is 1)
;       dimensions              two-element array giving dimensions of the plotting window in device coordinates, optional
;       location                two-element array giving location of the plotting window in device coordinates, optional
;       timestamps_color        a string giving the color to overplot timestamps, optional (default is 'white')
;       
; KEYWORDS:
;       /NO_TIMESTAMPS          disable default behaviour of plotting timestamps
;       
; OUTPUT
;
; OUTPUT TYPE:
;
; EXAMPLES:
;       aurorax_montage_create, images, timestamps, 5, 5, colortable=7, timestamps_fontsize=16
;+
;-------------------------------------------------------------
pro aurorax_montage_create, images, timestamps, n_cols, n_rows, colortable=colortable, timestamps_fontsize=timestamps_fontsize, frame_step=frame_step, dimensions=dimensions, location=location, no_timestamps=no_timestamps
  ; Get the number of channels of image data
  images_shape = size(images, /dimensions)
  if n_elements(images_shape) eq 2 then begin
    print, "[aurorax_montage_create] Error: 'images' must contain multiple frames."
    goto, error_jump
  endif else if n_elements(images_shape) eq 3 then begin
    if images_shape[0] eq 3 then begin
      print, "[aurorax_montage_create] Error: 'images' must contain multiple frames."
      goto, error_jump
    endif
    n_channels = 1
  endif else if n_elements(images_shape) eq 4 then begin
    n_channels = images_shape[0]
  endif else begin
    print, "[aurorax_montage_create] Error: Unable to determine number of channels based on the supplied images. " + $
           "Make sure you are supplying a [cols,rows,images] or [channels,cols,rows,images] sized array."
    goto, error_jump
  endelse
  
  if not keyword_set(frame_step) then frame_step = 1
  
  ; Make sure requested montage size fits number of images provided
  n_img = (size(images, /dimensions))[-1]
  n_ts = n_elements(timestamps)
  n_montage_img = n_cols * n_rows
  
  if (n_img ne n_ts) then begin
    print, "[aurorax_montage_create] Error: Number of images provided does not match number of timestamps provided."
    goto, error_jump
  endif
  if (floor(n_ts / float(frame_step)) lt n_montage_img) then begin
    print, "[aurorax_montage_create] Error: Not enough images provided to create desired montage."
    goto, error_jump
  endif
  
  ; set default values
  if not keyword_set(colortable) then colortable = 0
  if not keyword_set(dimensions) then dimensions = [n_cols*150, n_rows*131]
  if not keyword_set(position) then position = [5, 5]
  if not keyword_set(timestamps_fontsize) then timestamps_fontsize = 12
  if not keyword_set(timestamps_color) then timestamps_color = 'white'
  
  ; Create the plot
  w = window(dimensions = dimensions, location=location, margin=0, /no_toolbar)
  
  ; convert images to bytes
  images = bytscl(images)
  
  ; index array used to determine where in the montage we are
  montage_arr = indgen(n_cols, n_rows)
  
  ; iterate through and add each frame to plot
  montage_frame_num = 1
  for i=0, n_img-frame_step, frame_step do begin
    ; get timestamp location
    tmp = array_indices(montage_arr, where(montage_arr eq montage_frame_num-1))
    x = tmp[0] * (dimensions[0]/n_cols) + (dimensions[0]/2)/(n_cols)
    y = dimensions[1] - tmp[1] * (dimensions[1]/n_rows) - (dimensions[1])/(n_rows) + 5
    
    ; plot image and timestamp
    if n_channels eq 1 then begin    
      im = image(images[*,*,i], rgb_table=colortable, /current, layout=[n_cols, n_rows, montage_frame_num], margin=0)
      if not keyword_set(no_timestamps) then begin
        ts = text(x, y, strmid(timestamps[i], 11, 8), font_size=timestamps_fontsize, color=timestamps_color, alignment=0.5, /device)
      endif
    endif else begin
      im = image(images[*,*,*,i], /current, layout=[n_cols, n_rows, montage_frame_num], margin=0)
      if not keyword_set(no_timestamps) then begin
        ts = text(x, y, strmid(timestamps[i], 11, 8), font_size=timestamps_fontsize, color=timestamps_color, alignment=0.5, /device)
      endif
    endelse
    montage_frame_num += 1
    if montage_frame_num-1 eq n_montage_img then break
  endfor
  error_jump:
end
  