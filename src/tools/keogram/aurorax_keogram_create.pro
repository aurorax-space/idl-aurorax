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

;+
; :Description:
;       Create a keogram structure from an array of image data.
;
; :Parameters:
;       images: in, required, Array
;         array of images or spectrograph data to extract metric from
;       time_stamp: in, required, Array
;         array of timestamps corresponding to each frame in images
;
; :Keywords:
;       axis: in, optional, Integer
;         the axis index (1 or 0) to slice the keogram from - default is 1 (N-S slice)
;       spectra: in, optional, Boolean
;         indicates that spectrograph data is being passed in
;       spect_emission: in, optional, String
;         a string giving a known auroral emission to perform integration over for
;         creation of spectrograph keograms, either ['hbeta', 'blue', 'green', 'red'],
;         defaults to 'green'
;       spect_band_signal: in, optional, Float
;         a two-element array used to manually supply the wavelengths to use as the
;         lower and upper bounds of integration of the spectrum, useful for keograms
;         of emissions that are not available in the spect_emission parameter
;       spect_band_bg: in, optionial, Float
;         a two-element array specifying the wavelengths to use as the lower and
;         upper bounds of integration for a background channel, which is subtracted
;         from the integration over spect_band for manual emission selection
;       wavelength: in, optional, Float
;         the array of wavelengths corresponding to spectrograph data
;
; :Returns:
;       Struct
;
; :Examples:
;       keogram = aurorax_keogram_create(img, time_stamp)
;       ewogram = aurorax_keogram_create(img, time_stamp, axis=1)
;+
function aurorax_keogram_create, $
  images, $
  time_stamp, $
  axis = axis, $
  spectra = spectra, $
  spect_emission = spect_emission, $
  spect_band_signal = spect_band_signal, $
  spect_band_bg = spect_band_bg, $
  wavelength = wavelength

  if not isa(images, /array) then begin
    print, '[aurorax_keogram_create] Error: ''images'' must be an array.'
    return, !null
  endif

  ; Determine which dimension to slice keogram from
  if not keyword_set(axis) then axis = 0
  if axis ne 0 and axis ne 1 then begin
    print, '[aurorax_keogram_create] Error: Allowed axis values are 0 or 1.'
    return, !null
  endif

  ; Get the number of channels of image data
  images_shape = size(images, /dimensions)
  if n_elements(images_shape) eq 2 then begin
    print, '[aurorax_keogram_create] Error: ''images'' must contain multiple frames.'
    return, !null
  endif else if n_elements(images_shape) eq 3 then begin
    if images_shape[0] eq 3 then begin
      print, '[aurorax_keogram_create] Error: ''images'' must contain multiple frames.'
      return, !null
    endif
    n_channels = 1
  endif else if n_elements(images_shape) eq 4 then begin
    n_channels = images_shape[0]
  endif else begin
    print, '[aurorax_keogram_create] Error: Unable to determine number of channels based on the supplied images. ' + $
      'Make sure you are supplying a [cols,rows,images] or [channels,cols,rows,images] sized array.'
    return, !null
  endelse

  ; Check spectrograph inputs
  if keyword_set(spectra) then begin

    ; check that wavelengths are supplied
    if ~ keyword_set(wavelength) then begin
      print, '[aurorax_keogram_create] Error: ''wavelength'' must be supplied for spectrograph data.'
    endif

    ; check shape
    if n_elements(images_shape) ne 3 then begin
      print, '[aurorax_keogram_create] Error: ''images'' must be a 3-dimensional array for spectrograph data.'
      return, !null
    endif

    ; check that input emissions are valid
    if keyword_set(spect_emission) and (keyword_set(spect_band_signal) or keyword_set(spect_band_bg_))then begin
      print, '[aurorax_keogram_create] Error: only one of ''spect_emission'' and ''spect_band_signal''/''spect_band_bg'' may be set'
      return, !null
    endif else if ~ keyword_set(spect_emission) and ~ keyword_set(spect_band_signal) then begin
      spect_emission = 'green'
    endif else if keyword_set(spect_emission) then begin
      if ~ isa(spect_emission, /string) then begin
        print, '[aurorax_keogram_create] Error: ''spect_emission'' must be a string'
        return, !null
      endif
      if where(['hbeta', 'blue', 'green', 'red'] eq spect_emission, /null) eq !null then begin
        print, '[aurorax_keogram_create] Error: input spect_emission='''+spect_emission+''' is not recognized... ' + $
          'please select one of [''hbeta'', ''blue'', ''green'', ''red''], or pass in a manual wavelength range with ''spect_band_signal''
        return, !null
      endif
    endif
  endif

  ; handle creation of spectrograph keograms seperately
  if keyword_set(spectra) then begin
    
    instrument_type = 'spectrograph' 
    
    ; available automatic selections
    if isa(spect_emission) then begin
      wavelength_range = (hash('green', [557.0 - 1.5, 557.0 + 1.5], $
        'red', [630.0 - 1.5, 630.0 + 1.5], $
        'blue', [427.8 - 3.0, 427.8 + 0.5], $
        'hbeta', [486.1 - 1.5, 486.1 + 1.5]))[spect_emission]

      wavelength_bg_range = (hash('green', [552.0 - 1.5, 552.0 + 1.5], $
        'red', [625.0 - 1.5, 625.0 + 1.5], $
        'blue', [430.0 - 1.0, 430.0 + 1.0], $
        'hbeta', [480.0 - 1.0, 480.0 + 1.0]))[spect_emission]
    endif else if isa(spect_band_signal) then begin
      ; manually supplied wavelength range for integration
      if n_elements(spect_band_signal) ne 2 or (~ isa(spect_band_signal, /float) and ~ isa(spect_band_signal, /int)) then begin
        print, '[aurorax_keogram_create] Error: ''spect_band_signal'' must be a 2-element array of wavelengths'
        return, !null
      endif
      wavelength_range = spect_band_signal

      if isa(spect_band_bg) then begin
        if n_elements(spect_band_bg) ne 2 or (~ isa(spect_band_bg, /float) and ~ isa(spect_band_bg, /int)) then begin
          print, '[aurorax_keogram_create] Error: ''spect_band_bg'' must be a 2-element array of wavelengths'
          return, !null
        endif
        wavelength_bg_range = spect_band_bg
      endif else begin
        wavelength_bg_range = !null
      endelse
    endif

    ; now, creating the actual spectrograph keogram
    ;
    ; first, get indices of integration
    int_w = where(wavelength ge wavelength_range[0] and wavelength lt wavelength_range[1], /null)
    if int_w eq !null then begin
      print, '[aurorax_keogram_create] Error: desired wavelength integration range does not exist within ''wavelength'''
      return, !null
    endif
    if wavelength_bg_range ne !null then begin
      int_bg_w = where(wavelength ge wavelength_bg_range[0] and wavelength lt wavelength_bg_range[1], /null)
      if int_bg_w eq !null then begin
        print, '[aurorax_keogram_create] Error: desired background wavelength integration range does not exist within ''wavelength'''
        return, !null
      endif
    endif else begin
      int_bg_w = !null
      print, '[aurorax_keogram_create] Warning: performing integration over wavelength range without background ' + $
        'subtraction - use ''spect_band_bg'' to set a background channel for integration.'
    endelse
    
    ; ensure data dimensionality is consistent with supplied wavelengths and timestamps
    spectra_shape = size(images, /dimensions)
    n_wavelengths_in_spectra = spectra_shape[1]
    n_spatial_bins = spectra_shape[0]
    n_timestamps_in_spectra = spectra_shape[2]
    n_wavelengths = n_elements(wavelength)
    n_timestamps = n_elements(time_stamp)
    
    if n_timestamps ne n_timestamps_in_spectra then begin
      print, '[aurorax_keogram_create] Error: mismatched timestamp dimensions. Received '+strcompress(string(n_timestamps),/remove_all) + $
             ' timestamps for spectrograph data with '+strcompress(string(n_timestamps_in_spectra),/remove_all)+' timestamps.'
      return, !null
    endif
    
    if n_wavelengths ne n_wavelengths_in_spectra then begin
      print, '[aurorax_keogram_create] Error: mismatched wavelength dimensions. Received '+strcompress(string(n_wavelengths),/remove_all) + $
        ' wavelengths for spectrograph data with '+strcompress(string(n_wavelengths_in_spectra),/remove_all)+' wavelengths.'
      return, !null
    endif
    
    ; set y-axis and keo index
    ccd_y = indgen(n_spatial_bins)
    keo_idx = 0
    
    ; initialize keogram array
    keo_arr = make_array([n_timestamps, n_spatial_bins], type=size(images, /type))
    
    ; iterate through each timestamp and compute emissions for all spatial bins
    for i=0, n_spatial_bins-1 do begin
      for j=0, n_timestamps-1 do begin
        ; signal integration
        rayleighs = int_tabulated(wavelength[int_w], reform(images[i,int_w,j]))
        
        ; background integration if specified
        if int_bg_w ne !null then begin
          rayleighs -= int_tabulated(wavelength[int_bg_w], reform(images[i,int_bg_w,j]))
        endif
        
        ; in case of non-physical values
        if ~finite(rayleighs) or rayleighs lt 0 then rayleighs = 0
        
        ; insert into keogram array
        keo_arr[j,i] = rayleighs
      endfor
    endfor
    
    ; Spectrograph keogram generation is complete, now create object like normal and return
    ; 
    ; Convert timestamp strings to UT decimal
    ut_decimal = list()
    for i = 0, n_elements(time_stamp) - 1 do begin
      hh = fix(strmid(time_stamp[i], 11, 2))
      mm = fix(strmid(time_stamp[i], 14, 2))
      ss = fix(strmid(time_stamp[i], 17, 2))
      this_dec = hh + mm / 60.0 + ss / (60 * 60.0)
      ut_decimal.add, this_dec
    endfor
    ut_decimal = ut_decimal.toArray()

  ; Return keogram structure
    return, {data: keo_arr, ccd_y: ccd_y, slice_idx: keo_idx, timestamp: time_stamp, ut_decimal: ut_decimal, axis: axis, instrument_type: instrument_type}
    
  endif
  
  instrument_type = 'asi' 
  
  ; Extract the keogram slice, transpose and reshape for proper output shape
  if n_channels eq 1 then begin
    if axis eq 0 then begin
      keo_idx = images_shape[0] / 2
      keo_arr = transpose(reform(images[keo_idx, *, *]))
    endif else begin
      keo_idx = images_shape[1] / 2
      keo_arr = transpose(reform(images[*, keo_idx, *]))
    endelse
  endif else begin
    if axis eq 0 then begin
      keo_idx = images_shape[1] / 2
      keo_arr = reform(images[*, keo_idx, *, *])
      keo_arr = bytscl(transpose(keo_arr, [0, 2, 1]), min = 0, max = 255)
    endif else begin
      keo_idx = images_shape[2] / 2
      keo_arr = reform(images[*, *, keo_idx, *])
      keo_arr = bytscl(transpose(keo_arr, [0, 2, 1]), min = 0, max = 255)
    endelse
  endelse

  ; Create CCD Y axis
  if n_channels eq 1 then begin
    ccd_y = indgen((size(keo_arr, /dimensions))[1])
  endif else begin
    ccd_y = indgen((size(keo_arr, /dimensions))[2])
  endelse

  ; Convert timestamp strings to UT decimal
  ut_decimal = list()
  for i = 0, n_elements(time_stamp) - 1 do begin
    hh = fix(strmid(time_stamp[i], 11, 2))
    mm = fix(strmid(time_stamp[i], 14, 2))
    ss = fix(strmid(time_stamp[i], 17, 2))
    this_dec = hh + mm / 60.0 + ss / (60 * 60.0)
    ut_decimal.add, this_dec
  endfor
  ut_decimal = ut_decimal.toArray()

  ; Return keogram structure
    return, {data: keo_arr, ccd_y: ccd_y, slice_idx: keo_idx, timestamp: time_stamp, ut_decimal: ut_decimal, axis: axis, instrument_type: instrument_type}
end
