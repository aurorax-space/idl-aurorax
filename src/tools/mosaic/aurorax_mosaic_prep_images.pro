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

function __determine_cadence, timestamp_arr
  compile_opt hidden

  ; ;;
  ; Determines the cadence using a list of timestamps
  ; ;;
  diff_seconds = []
  curr_ts = !null
  checked_timestamps = 0

  for i = 0, n_elements(timestamp_arr) - 1 do begin
    ; bail out if we've checked 10 timestamps, that'll be enough
    if (checked_timestamps gt 10) then break

    if curr_ts eq !null then begin
      ; first iteration, initialize curr_ts variable
      curr_ts = timestamp_arr[i]
    endif else begin
      ; Calculate difference in seconds
      diff_sec = fix((strsplit((strsplit(timestamp_arr[i], ':', /extract))[-1], '.', /extract))[0]) - $
        fix((strsplit((strsplit(curr_ts, ':', /extract))[-1], '.', /extract))[0])
      diff_seconds = [diff_seconds, diff_sec]
      curr_ts = timestamp_arr[i]
    endelse
    checked_timestamps += 1
  endfor

  ; Get hash of occurrences of second differences
  sec_freq = hash()
  foreach elem, diff_seconds do begin
    sec_freq[elem] = 0
  endforeach
  foreach elem, diff_seconds do begin
    sec_freq[elem] += 1
  endforeach

  ; Set cadence to most common difference between timestamps
  cadence = !null
  max_occur = 0
  foreach sec, sec_freq.keys() do begin
    if sec_freq[sec] gt max_occur then begin
      max_occur = sec_freq[sec]
      cadence = sec
    endif
  endforeach

  if cadence eq !null then begin
    print, '[aurorax_mosaic_prep_images] Error: Could not determine cadence of image data.'
    return, !null
  endif

  return, cadence
end

function __get_julday, time_stamp
  compile_opt hidden

  ; ;;
  ; Splits a timestamp string into a struct with value of julian day
  ; and string field to use for comparisons.
  ;
  ; Note: Expects timestamps of the form: 'yyyy-mm-dd HH:MM:SS.ff utc'
  ; ;;

  if (not isa(time_stamp, /array)) then begin
    year = fix((strsplit(time_stamp, '-', /extract))[0])
    month = fix((strsplit(time_stamp, '-', /extract))[1])
    day = fix((strsplit(time_stamp, '-', /extract))[2])

    hour = fix((strsplit((strsplit(time_stamp, ' ', /extract))[1], ':', /extract))[0])
    minute = fix((strsplit((strsplit(time_stamp, ' ', /extract))[1], ':', /extract))[1])
    second = fix((strsplit((strsplit(time_stamp, ' ', /extract))[1], ':', /extract))[2])
  endif else begin
    year = fix(((strsplit(time_stamp, '-', /extract)).toarray())[*, 0])
    month = fix(((strsplit(time_stamp, '-', /extract)).toarray())[*, 1])
    day = fix(((strsplit(time_stamp, '-', /extract)).toarray())[*, 2])

    hour = fix(strmid((((strsplit(time_stamp, ':', /extract)).toarray())[*, 0]), 1, 2, /reverse_offset))
    minute = fix((((strsplit(time_stamp, ':', /extract)).toarray())[*, 1]))
    second = fix((((strsplit(time_stamp, ':', /extract)).toarray())[*, 2]))
  endelse

  return, julday(month, day, year, hour, minute, second)
end

;+
; :Description:
;       Prepare image data to create a mosaic.
;
;       Takes image data and formats it in a way such that it
;       can be fed into the aurorax_mosaic_plot routine.
;
; :Parameters:
;       image_list: in, required, List
;         A list of image data objects, where each object is usually the return
;         value of aurorax_ucalgary_read(). Note that even if preparing a single
;         image data object, it must be enclosed in a list.
;
; :Returns:
;       Struct
;
; :Examples:
;       prepped_data = aurorax_prep_images(list(aurorax_ucalgary_read(d.dataset, d.filenames)))
;+
function aurorax_mosaic_prep_images, $
  image_list, $
  spect_emission = spect_emission, $
  spect_band_signal = spect_band_signal, $
  spect_band_bg = spect_band_bg
  
  ; Verify that image_list is indeed a list, not array
  if (typename(image_list) ne 'LIST') then begin
    print, '[aurorax_mosaic_prep_images] Error: image_list must be a list, i.e. ''list(img_data_1, img_data_2, ...)''.'
    return, !null
  endif
  
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
  
  ; Determine the number of expected frames
  ;
  ; NOTE: this is done to ensure that the eventual image arrays are all the
  ; same size, and we adequately account for dropped frames.
  ;
  ; Steps:
  ; 1) finding the over-arching start and end times of data across all sites
  ; 2) determine the cadence using the timestamps
  ; 3) determine the number of expected frames using the cadence, start and end
  start_ts = __get_julday(image_list[0].timestamp[0])
  end_ts = __get_julday(image_list[0].timestamp[-1])
  foreach site_data, image_list do begin
    this_start_ts = __get_julday(site_data.timestamp[0])
    this_end_ts = __get_julday(site_data.timestamp[-1])
    if (this_start_ts lt start_ts) then start_ts = this_start_ts
    if (this_end_ts gt end_ts) then end_ts = this_end_ts
  endforeach

  ; Determine cadance, and generate all expected timestamps
  cadence = __determine_cadence(image_list[0].timestamp)
  expected_juldays = timegen(start = start_ts, final = end_ts, step_size = cadence, units = 'S')
  if (end_ts - start_ts) gt 3 then begin
    print, '[aurorax_mosaic_prep_images] Error: Excessive date range detected - Check that all data is from the same time range'
    return, !null
  endif
  expected_timestamps = string(expected_juldays, format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2, " ", CHI2.2, ":", CMI2.2, ":", CSI2.2))')
  expected_num_frames = n_elements(expected_timestamps)

  ; for each site
  site_uid_list = []
  data_type_list = []
  final_datatype_list = []
  images_dict = hash()
  dimensions_dict = hash()
  foreach site_image_data, image_list do begin
    site_data = site_image_data.data

    ; Add to site uid list
    if where(tag_names(site_image_data.metadata[0]) eq 'SITE_UID', /null) ne !null then begin
      site_uid = site_image_data.metadata[0].site_uid
    endif else begin
      if where(tag_names(site_image_data.metadata.file_meta[0]) eq 'SITE_UID', /null) ne !null then begin
        site_uid = site_image_data.metadata.file_meta[0].site_uid
      endif else begin
        print, '[aurorax_mosaic_prep_images] Error: Could not find SITE_UID when parsing metadata.'
        return, !null
      endelse
    endelse

    ; Determine number of channels of image data
    if (size(site_data, /dimensions))[0] eq 3 then begin
      n_channels = 3
    endif else begin
      n_channels = 1
    endelse
    
    int_w = !null
    int_bg_w = !null
    wavelength = !null
    
    ; Check if spect or asi data and keep track
    if strpos(strlowcase(site_image_data.dataset.name), 'spect') ne -1 then begin
      n_channels = 1
      current_data_type = 'spect'
      data_type_list = [data_type_list, current_data_type]

      ; extract wavelength from metadata and get integration indices
      wavelength = site_image_data.metadata.wavelength
      int_w = where(wavelength ge wavelength_range[0] and wavelength le wavelength_range[1])
      if wavelength_bg_range ne !null then begin
        int_bg_w = where(wavelength ge wavelength_bg_range[0] and wavelength le wavelength_bg_range[1])
      endif
      ; set spect dimensions
      height = (size(site_data.spectra, /dimensions))[0]
      if where(dimensions_dict.keys() eq site_uid, /null) ne !null then begin
        dimensions_dict[site_uid+'_spect'] = [height]
      endif else begin
        dimensions_dict[site_uid] = [height]
      endelse
    endif else begin
      current_data_type = 'asi'
      data_type_list = [data_type_list, current_data_type]
      
      ; set image dimensions
      if n_channels eq 1 then begin
        height = (size(site_data, /dimensions))[1]
        width = (size(site_data, /dimensions))[0]
      endif else begin
        height = (size(site_data, /dimensions))[2]
        width = (size(site_data, /dimensions))[1]
      endelse
      if where(dimensions_dict.keys() eq site_uid, /null) ne !null then begin
        dimensions_dict[site_uid+'_asi'] = [width, height]
      endif else begin
        dimensions_dict[site_uid] = [width, height]
      endelse
    endelse
    
    ; We don't attempt to handle the same site being passed in for multiple networks
    if where(site_uid eq images_dict.keys(), /null) ne !null then begin
      ; We need to check if there is ASI and spect data from the same site, as that
      ; is fine to go into the same mosaic
      
      d_keys = (images_dict.keys()).toarray()
      if data_type_list[where(d_keys eq site_uid)] ne current_data_type then begin
        site_uid += '_' + current_data_type
      endif else begin
        print, strupcase(site_uid), format = 'Same site between differing networks detected. Omitting additional %s data'
        continue
      endelse
    endif

    site_uid_list = [site_uid_list, site_uid]
    final_datatype_list = [final_datatype_list, current_data_type]
    
    ; initialize this site's image data variable
    if current_data_type eq 'asi' then begin
      site_images = reform(make_array(n_channels, width, height, expected_num_frames, /double, value = !values.f_nan))
    endif else if current_data_type eq 'spect' then begin
      site_images = reform(make_array(height, expected_num_frames, /double, value = !values.f_nan))
    endif

    ; find the index in the data corresponding to each expected timestamp
    for i = 0, n_elements(expected_timestamps) - 1 do begin
      found_idx = where(((strsplit(site_image_data.timestamp, '.', /extract)).toarray())[*, 0] eq expected_timestamps[i], /null)
      
      if found_idx eq !null then begin
        found_idx = where(strmid(((strsplit(site_image_data.timestamp, '.', /extract)).toarray())[*, 0],0,19) eq expected_timestamps[i], /null)
      endif
      
      ; didn't find the timestamp, just move on because there will be no data for this timestamp
      if found_idx eq !null then continue
      
      ; Add data to array
      if current_data_type eq 'asi' then begin
        if n_channels eq 1 then begin
          site_images[*, *, i] = site_data[*, *, found_idx]
        endif else begin
          site_images[*, *, *, i] = site_data[*, *, *, found_idx]
        endelse
      endif else if current_data_type eq 'spect' then begin
        spectra = site_data.spectra[*,*,found_idx]
        rayleighs_arr = make_array((size(spectra,/dimensions))[0], /double, value=!values.f_nan)
        
        ; iterate through each spectrograph bin
        for spect_bin=0, n_elements(rayleighs_arr)-1 do begin
          ; signal integration
          rayleighs = int_tabulated(wavelength[int_w], reform(spectra[spect_bin,int_w]))
          
          ; background integration if specified
          if int_bg_w ne !null then begin
            rayleighs -= int_tabulated(wavelength[int_bg_w], reform(spectra[spect_bin,int_bg_w]))
          endif
          
          ; in case of non-physical values
          if ~finite(rayleighs) or rayleighs lt 0.0 then rayleighs = 0.0
          
          ; insert into keogram array
          rayleighs_arr[spect_bin] = rayleighs
        endfor
        site_images[*, i] = rayleighs_arr
      endif
    endfor

    ; insert this site's image data variable into image data hash
    images_dict[site_uid] = site_images
  endforeach

  ; cast into mosaic_data struct
  prepped_data = hash('site_uid', site_uid_list, 'timestamps', expected_timestamps, 'images', images_dict, 'images_dimensions', dimensions_dict, 'data_types', final_datatype_list)
  
  return, prepped_data
end
