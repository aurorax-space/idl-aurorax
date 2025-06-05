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
;       Integrate spectrograph data to obtain absolute intensity, for a given common
;       auroral emission or a manually selected wavelength band.
;
; :Parameters:
;       spect_data: in, required, Struct
;         spectrograph data object to integrate, usually the return value of aurorax_ucalgary_read()
;       time_stamp: in, required, String
;         timestamp(s) for which spectral data will be integrated
;       spect_loc: in, required, Int
;         the bin number, corresponding to the spatial axis of the spectrograph
;         data, to integrate data for
;
; :Keywords:
;       spect_emission: in, optional, String
;         a string giving a known auroral emission to perform integration over,
;         either ['hbeta', 'blue', 'green', 'red'], defaults to 'green'
;       spect_band_signal: in, optional, Float
;         a two-element array used to manually supply the wavelengths to use as the
;         lower and upper bounds of integration of the spectrum
;       spect_band_bg: in, optionial, Float
;         a two-element array specifying the wavelengths to use as the lower and
;         upper bounds of integration for a background channel, which is subtracted
;         from the integration over spect_band for manual emission selection
;
; :Examples:
;       i_4278 = aurorax_spectra_get_intensity(spect_data, '2021-02-16T09:30:00', 125, spect_emission='blue')
;       i_4861 = aurorax_spectra_get_intensity(spect_data, '2021-02-16T09:30:00', 125, spect_emission='hbeta')
;       i_5577 = aurorax_spectra_get_intensity(spect_data, '2021-02-16T09:30:00', 125, spect_emission='green')
;       i_6300 = aurorax_spectra_get_intensity(spect_data, '2021-02-16T09:30:00', 125, spect_emission='red')
;+
function aurorax_spectra_get_intensity, $
  spect_data, $
  time_stamp, $
  spect_loc, $
  spect_emission = spect_emission, $
  spect_band_signal = spect_band_signal, $
  spect_band_bg = spect_band_bg
  
  ; pull out spectra, timestamps, wavelength from spect_data_objects
  spectra = spect_data.data.spectra
  ts = spect_data.timestamp
  wavelength = spect_data.metadata.wavelength
  
  ; check that input emissions are valid
  if keyword_set(spect_emission) and (keyword_set(spect_band_signal) or keyword_set(spect_band_bg))then begin
    print, '[aurorax_spectra_get_intensity] Error: only one of ''spect_emission'' and ''spect_band_signal''/''spect_band_bg'' may be set'
    return, !null
  endif else if ~ keyword_set(spect_emission) and ~ keyword_set(spect_band_signal) then begin
    spect_emission = 'green'
  endif else if keyword_set(spect_emission) then begin
    if ~ isa(spect_emission, /string) then begin
      print, '[aurorax_spectra_get_intensity] Error: ''spect_emission'' must be a string'
      return, !null
    endif
    if where(['hbeta', 'blue', 'green', 'red'] eq spect_emission, /null) eq !null then begin
      print, '[aurorax_spectra_get_intensity] Error: input spect_emission='''+spect_emission+''' is not recognized... ' + $
        'please select one of [''hbeta'', ''blue'', ''green'', ''red''], or pass in a manual wavelength range with ''spect_band_signal''
      return, !null
    endif
  endif
  
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
      print, '[aurorax_spectra_get_intensity] Error: ''spect_band_signal'' must be a 2-element array of wavelengths'
      return, !null
    endif
    wavelength_range = spect_band_signal

    if isa(spect_band_bg) then begin
      if n_elements(spect_band_bg) ne 2 or (~ isa(spect_band_bg, /float) and ~ isa(spect_band_bg, /int)) then begin
        print, '[aurorax_spectra_get_intensity] Error: ''spect_band_bg'' must be a 2-element array of wavelengths'
        return, !null
      endif
      wavelength_bg_range = spect_band_bg
    endif else begin
      wavelength_bg_range = !null
    endelse
  endif

  ; now, get indices of integration for wavelengths
  int_w = where(wavelength ge wavelength_range[0] and wavelength lt wavelength_range[1], /null)
  if int_w eq !null then begin
    print, '[aurorax_spectra_get_intensity] Error: desired wavelength integration range does not exist within ''wavelength'''
    return, !null
  endif
  if wavelength_bg_range ne !null then begin
    int_bg_w = where(wavelength ge wavelength_bg_range[0] and wavelength lt wavelength_bg_range[1], /null)
    if int_bg_w eq !null then begin
      print, '[aurorax_spectra_get_intensity] Error: desired background wavelength integration range does not exist within ''wavelength'''
      return, !null
    endif
  endif else begin
    int_bg_w = !null
    print, '[aurorax_spectra_get_intensity] Warning: performing integration over wavelength range without background ' + $
      'subtraction - use ''spect_band_bg'' to set a background channel for integration.'
  endelse
  
  ; Turn input plotting timestamp and spect loc into arrays if they're scalars
  if isa(time_stamp, /scalar) then time_stamp = [time_stamp]
  if ~ isa(spect_loc, /scalar) or ~ isa(spect_loc, /int) then begin
    print, '[aurorax_spectra_get_intensity] Error: ''spect_loc'' must be a scalar integer
  endif
  
  ; Obtain indices along time dimension of spectra corresponding to requested timestamp(s)
  ts_idx_arr = []
  foreach t, time_stamp do begin
    ; search for ts in metadata array
    formatted_time_stamp = strjoin(strsplit(t, 'T', /regex, /extract), " ")+" UTC"
    idx = where(ts eq formatted_time_stamp, /null)

    ; raise error if timestamp doesn't exist in data
    if idx eq !null then begin
      print, '[aurorax_spectra_plot] Error: could not find data in spect_data for requested timestamp '+t+'.'
      return, !null
    endif
    ts_idx_arr = [ts_idx_arr, idx]
  endforeach
  
  ; Integrate spectral data for each timestamp at the requested bin and store resultant
  ; intensity (which is in Rayleighs) in array
  intensity_arr = []
  foreach ts_idx, ts_idx_arr do begin
  
    ; extract spectrum for this timestamp
    spectrum = reform(spectra[spect_loc, *, ts_idx])
    
    ; integrate over signal channel and if requested, subtract background channel integral
    rayleighs = int_tabulated(wavelength[int_w], spectrum[int_w])
    if int_bg_w ne !null then begin
      rayleighs -= int_tabulated(wavelength[int_bg_w], spectrum[int_bg_w])
    endif
    
    ; append to array
    intensity_arr = [intensity_arr, rayleighs]
  endforeach
  
  return, intensity_arr
end














