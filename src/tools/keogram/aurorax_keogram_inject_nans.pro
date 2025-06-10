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
;       Add NaN columns to a keogram to represent missing data. The imager cadence,
;       unless manually supplied, is automatically determined to decide where data
;       is missing in the keogram.
;
; :Parameters:
;       keogram: in, required, Struct
;         the keogram object to inject nans into
;
; :Keywords:
;       cadence: in, optional, Float or Int
;         the cadence, in seconds, of the keogram data - supplying a cadence will
;         override the default behaviour, which is to automatically determine the
;         imager cadence based on the keogram data
;       fill_val: in, optional, Float or Int
;         the value to represent missing data with. The default is !values.f_nan
;
; :Returns:
;       Struct
;
; :Examples:
;       keo = aurorax_keogram_create(img, time_stamp)
;       keo_with_missing_data = aurorax_keogram_inject_nans(keo)
;+
function aurorax_keogram_inject_nans, $
  keogram, $
  cadence = cadence, $
  fill_val = fill_val
  ; First, determine the apparent cadence based on the keogram, regardless
  ; of whether or not a manual cadence was supplied
  apparent_cadence = __aurorax_determine_cadence(keogram.timestamp)

  ; Check if cadence was supplied
  if keyword_set(cadence) then begin
    ; Give a warning if the user-supplied cadence is different then that determined from the data
    if cadence ne apparent_cadence then begin
      print, '[aurorax_keogram_inject_nans] Warning: based on the keogram''s timestamp attribute, the apparent cadence is' + $
        strcompress(string(apparent_cadence), /remove_all) + ' s, but ' + strcompress(string(apparent_cadence), /remove_all) + $
        ' s was passed via the cadence kewyord. ensure that the selected cadence is correct for the dataset being wrong.'
      return, !null
    endif
  endif else begin
    ; Otherwise, use the automatically determined cadence
    cadence = apparent_cadence
  endelse

  ; Default fill value is NaN
  if keyword_set(fill_val) then begin
    filling_value = fill_val
  endif else begin
    filling_value = !values.f_nan
  endelse

  ; Determine whether keogram is single channel or RGB
  if (size(keogram.data, /dimensions))[0] eq 3 and n_elements(size(keogram.data, /dimensions)) eq 3 then begin
    n_channels = 3
  endif else begin
    n_channels = 1
  endelse

  ; Cannot inject_nans into keogram that spans multiple days
  if (strmid(keogram.timestamp[0], 0, 10) ne strmid(keogram.timestamp[-1], 0, 10)) then begin
    print, '[aurorax_keogram_inject_nans] Error: cannot inject NaNs into keogram that spans more than one day'
    return, !null
  endif

  ; The first step is checking if there actually is any missing data in this keogram
  start_ts = (strsplit(keogram.timestamp[0], /extract, ' '))[1]
  end_ts = (strsplit(keogram.timestamp[-1], /extract, ' '))[1]

  ; Check that timestamps are formatted as expected
  if strmid(start_ts, 2, 1) ne ':' or strmid(start_ts, 5, 1) ne ':' or strmid(end_ts, 2, 1) ne ':' or strmid(end_ts, 5, 1) ne ':' then begin
    print, '[aurorax_keogram_inject_nans] Error: unexpected timestamp in keogram object. Expested format ''yyyy-mm-dd HH:MM:SS.MS utc'''
    return, !null
  endif

  ; Compute deltas between timestamps
  hr_delta = float(strmid(end_ts, 0, 2)) - float(strmid(start_ts, 0, 2))
  mn_delta = float(strmid(end_ts, 3, 2)) - float(strmid(start_ts, 3, 2))
  sc_delta = float(strmid(end_ts, 6, 2)) - float(strmid(start_ts, 6, 2))
  if strlen(start_ts) gt 8 then begin
    ms_delta = (float(strmid(end_ts, 9, 3) + '.' + strmid(end_ts, 12, 100))) - (float(strmid(start_ts, 9, 3) + '.' + strmid(start_ts, 12, 100)))
  endif else begin
    ms_delta = 0.0
  endelse

  ; If cadence is supplied or calculated to be less than zero, we proceed
  ; under the assumption tha we are working with burst data
  if (cadence lt 1.0) then begin
    is_burst = 1
  endif else begin
    is_burst = 0
  endelse

  ; Compute total time difference with millisecond precision, to determine expected number
  ; of frames in data range based on cadence
  total_s_delta = (hr_delta * 3600000.0 + mn_delta * 60000.0 + sc_delta * 1000.0 + ms_delta) / 1000.0
  n_desired_frames = round(total_s_delta / cadence) + 1

  ; Get the actual number of frames in the keogram
  if (n_channels eq 1) then begin
    n_keogram_frames = (size(keogram.data, /dimensions))[0]
  endif else begin
    n_keogram_frames = (size(keogram.data, /dimensions))[1]
  endelse

  ; If no data is missing we just print a user message and return the keogram
  if (n_desired_frames eq n_keogram_frames) then begin
    print, '[aurorax_keogram_inject_nans] Warning: returning input keogram unchanged as no missing data was detected'
    return, keogram
  endif

  ; Otherwise, we need to find which of the expected timestamps are missing
  ;
  ; First, we create a new keogram array with the correct size
  ; for the expected number of frames and a new timestamp list
  if (n_channels eq 1) then begin
    if finite(filling_value) then begin
      filled_keogram = make_array(n_desired_frames, (size(keogram.data, /dimensions))[1], type = size(keogram.data, /type))
    endif else begin
      filled_keogram = make_array(n_desired_frames, (size(keogram.data, /dimensions))[1], type = 4)
    endelse
  endif else begin
    if finite(filling_value) then begin
      filled_keogram = make_array(3, n_desired_frames, (size(keogram.data, /dimensions))[2], type = size(keogram.data, /type))
    endif else begin
      filled_keogram = make_array(3, n_desired_frames, (size(keogram.data, /dimensions))[2], type = 4)
    endelse
  endelse
  desired_timestamp = list()
  desired_timestamp_indices = []

  ; Create a tolerance for checking if timestamps exist. Default is
  ; one second, unless working with burst data, in which case the
  ; default tolerance is one sixth of a second
  if (is_burst eq 1) then begin
    tol = julday(0, 0, 1, 0, 0, 1.0 / 6.0) - julday(0, 0, 1, 0, 0, 0.0)
  endif else begin
    tol = julday(0, 0, 1, 0, 0, 1.0) - julday(0, 0, 1, 0, 0, 0.0)
  endelse

  ; Get the cadence as a juliand ata
  cadence_jul = julday(0, 0, 1, 0, 0, float(cadence)) - julday(0, 0, 1, 0, 0, 0.0)

  ; Fill the list of desired timestamps based on the cadence
  ;
  ; For each *desired* timestamp, we use a binary search to determine whether
  ; or not that timestamp already exist in the data, within tolerance
  target_jul = julday(fix(strmid(keogram.timestamp[0], 5, 2)), fix(strmid(keogram.timestamp[0], 8, 2)), $
    fix(strmid(keogram.timestamp[0], 0, 4)), fix(strmid(keogram.timestamp[0], 11, 2)), $
    fix(strmid(keogram.timestamp[0], 14, 2)), float(strmid(keogram.timestamp[0], 17, 100)))
  for i = 0, n_desired_frames - 1 do begin
    low = 0
    high = n_elements(keogram.timestamp) - 1
    match_idx = !null

    ; binary search
    while low le high do begin
      mid = fix((low + high) / 2.0)
      mid_jul = julday(fix(strmid(keogram.timestamp[mid], 5, 2)), fix(strmid(keogram.timestamp[mid], 8, 2)), $
        fix(strmid(keogram.timestamp[mid], 0, 4)), fix(strmid(keogram.timestamp[mid], 11, 2)), $
        fix(strmid(keogram.timestamp[mid], 14, 2)), float(strmid(keogram.timestamp[mid], 17, 100)))

      if (mid_jul lt target_jul - tol) then begin
        low = mid + 1
      endif else if (mid_jul gt target_jul + tol) then begin
        high = mid - 1
      endif else begin
        ; Timestamp has been found (within tolerance)
        match_idx = mid
        high = mid - 1
      endelse
    endwhile

    ; If we've found a mataching timestamp, insert it into the new timestamp array,
    ; and otherwise just insert the desired timestamp
    if isa(match_idx) then begin
      desired_timestamp.add, keogram.timestamp[match_idx]

      ; Add the index into the original keogram that corresponds to this timestamp
      desired_timestamp_indices = [desired_timestamp_indices, match_idx]
    endif else begin
      caldat, target_jul, mm, dd, yy, hr, mn, sc
      missing_ts = string(yy, format = '(I4.4)') + '-' + string(mm, format = '(I2.2)') + '-' + string(dd, format = '(I2.2)') + ' ' + $
        string(hr, format = '(I2.2)') + ':' + string(mn, format = '(I2.2)') + ':' + string(fix(sc), format = '(I2.2)') + $
        '.' + (strsplit(strcompress(string(float(sc)), /remove_all), '.', /extract))[-1] + ' utc'

      desired_timestamp.add, missing_ts

      ; Add NaN to the original keogram that corresponds to this timestamp
      desired_timestamp_indices = [desired_timestamp_indices, !values.f_nan]
    endelse
    target_jul += cadence_jul
  endfor

  ; Now that we have our desired timestamps we can go through and fill the new keogram array
  for i = 0, n_elements(desired_timestamp) - 1 do begin
    keo_idx = desired_timestamp_indices[i]

    ; If this desired_timestamp had no data, fill the keogram column with NaN (or
    ; another fill value set by keyword fill_val
    if ~finite(keo_idx) then begin
      ; fill this column with fill val
      if (n_channels eq 1) then begin
        filled_keogram[i, *] = filling_value
      endif else begin
        filled_keogram[*, i, *] = filling_value
      endelse
    endif else begin
      ; fill this column with original keogram data
      if (n_channels eq 1) then begin
        filled_keogram[i, *] = keogram.data[keo_idx, *]
      endif else begin
        filled_keogram[*, i, *] = keogram.data[*, keo_idx, *]
      endelse
    endelse
  endfor

  ; return an updated keogram structure, with the new data and timestamp list
  return, {data: filled_keogram, $
    ccd_y: keogram.ccd_y, $
    slice_idx: keogram.slice_idx, $
    timestamp: desired_timestamp, $
    ut_decimal: keogram.ut_decimal, $
    axis: keogram.axis, $
    instrument_type: keogram.instrument_type}
end
